class GotoTransaction < ActiveRecord::Base
  # Statuses:
  #   'R' => Received
  #   'A' => Accepted
  #   'D' => Declined
  #   'G' => Paid (Approved)
  #   'E' => Processing Error
  #  lowercase of the above denotes refund
  # Status Queries:
  #   Accepted?        [AG]
  #   Received?        [RDAGE]
  #   Paid?            [G]
  #   Declined?        [D]
  #   ProcessingError? [E]

  @nologging = true

  belongs_to :batch, :class_name => 'EftBatch', :foreign_key => 'batch_id'
  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_id'
  belongs_to :eft, :class_name => 'Helios::Eft', :foreign_key => 'client_id'

  serialize :goto_invalid, Array

  is_searchable :by_query => 'goto_transactions.first_name LIKE :like_query OR goto_transactions.last_name LIKE :like_query OR goto_transactions.credit_card_number LIKE :like_query OR goto_transactions.bank_account_number LIKE :like_query OR goto_transactions.client_id = :query',
    :and_filters    => {
      'batch_id'    => 'goto_transactions.batch_id = ?',
      'tran_type'   => 'goto_transactions.tran_type = ?',
      'has_eft'     => '(goto_transactions.no_eft != ? OR goto_transactions.no_eft IS NULL)', # Should be a 1
      'no_eft'      => 'goto_transactions.no_eft = ?', # Should be a 1
      'goto_invalid'=> '(goto_transactions.goto_invalid IS NOT NULL AND NOT(goto_transactions.goto_invalid LIKE ?))',
      'goto_valid'  => '(goto_transactions.goto_invalid IS NULL OR goto_transactions.goto_invalid LIKE ?)',
      'location'    => 'goto_transactions.location = ?',
      'amount'      => 'goto_transactions.amount = ?',
      'completed'   => '(goto_transactions.status IS NOT NULL AND goto_transactions.status != ?)', # Should test for a ''
      'in_progress' => '(goto_transactions.status IS NULL OR goto_transactions.status = ?)', # Should test for a ''
      'status'      => 'goto_transactions.status = ?',
      'client_id'   => 'goto_transactions.client_id = ?',
      'ach_submitted' => "goto_transactions.ach_submitted = ?"
    }

  def initialize(*attrs)
    #Give me:
    #batch_id, cp
    #batch_id, eft
    #or just {attributes}
    attrs = {} if attrs.blank?

    # If we're looking at a cp, change the attrs to look at it's eft, or simple attributes if no eft.
    if(attrs[1].is_a?(Helios::ClientProfile))
      batch_id = attrs[0]
      cp = attrs[1]
      # If there is no eft, turn straight into {attributes}
      if(cp.eft.nil?)
        location_code = '0'*(3-ZONE[:Location_Bits])+cp.id.to_s[0,ZONE[:Location_Bits]]
        attrs = {
          :batch_id => batch_id,
          :client_id => cp.id.to_i,
          :location => location_code,
          :first_name => cp.First_Name,
          :last_name => cp.Last_Name #,
          # :address => "#{cp.Address}, #{cp.City}, #{cp.State} #{cp.Zip}"
        }
      else # If there is an eft, turn attrs into [batch_id, eft]
        attrs[1] = cp.eft
      end
    end

    # At this point, attrs is either [batch_id, eft] or {attributes}
    # Handle [batch_id, eft]: turn them into {attributes}
    if(attrs[1].is_a?(Helios::Eft))
      batch_id = attrs[0]
      eft = attrs[1]
      location_code = eft.Location || '0'*(3-ZONE[:Location_Bits])+eft.Client_No.to_s[0,ZONE[:Location_Bits]]
      amount_int = eft.Monthly_Fee.to_f.to_s

      attrs = {
        :batch_id => batch_id,
        :client_id => eft.id.to_i,
        :location => location_code,
        :first_name => eft.First_Name,
        :last_name => eft.Last_Name,
        :bank_routing_number => eft.Bank_ABA,
        :bank_account_number => eft.credit_card? ? nil : eft.Acct_No,
        :name_on_card => eft.First_Name.to_s + ' ' + eft.Last_Name.to_s,
        :credit_card_number => eft.credit_card? ? eft.Acct_No : nil,
        :expiration => eft.Acct_Exp.to_s.gsub(/\D/,''),
        :amount => amount_int,
        :tran_type => eft.credit_card? ? 'Credit Card' : 'ACH',
        :account_type => eft.Acct_Type,
        :authorization => 'Written'
      }
    elsif attrs.is_a?(Array)
      attrs = *attrs
    end

    attrs[:no_eft] = (Helios::Eft.find_by_Client_No(attrs[:client_id]).nil? ? true : false) if attrs[:client_id]
    attrs[:first_name].to_s.gsub!(/[^A-Za-z0-9 ]/, '')
    attrs[:last_name].to_s.gsub!(/[^A-Za-z0-9 ]/, '')
    attrs[:name_on_card].to_s.gsub!(/[^A-Za-z0-9 ]/, '')

    # With only {attributes} at this point, make sure we're not duplicating records.
    if exis = self.class.find_by_batch_id_and_client_id(attrs[:batch_id], attrs[:client_id])
      # Pretend to be the existing record.
      super(exis.attributes.merge(attrs))
      self.id = exis.id
      @new_record = false
    else
      super(attrs)
    end

    # Generate a check_number (unique transaction number per-customer)
    get_check_number
    # Refresh invalid-ness
    goto_is_valid?
  end

  def goto_is_invalid?
    !goto_is_valid?
  end

  begin # Financial Information
  def credit_card?
    !['C','S'].include?(account_type)
  end
  def mc?
    credit_card_number.to_s[0,1] == '5'
  end
  def vs?
    credit_card_number.to_s[0,1] == '4'
  end
  def mc_vs?
    mc? || vs?
  end
  def amex?
    credit_card_number.to_s[0,1] == '3'
  end
  def discover?
    credit_card_number.to_s[0,1] == '6'
  end
  def dcas_card_type
    amex? ? 'AMEX' : (discover? ? 'DSVR' : (mc? ? 'MCRD' : (vs? ? 'VISA' : ''))) # We probably don't accept DinersClub cards, but that's the only one left?
  end

  def ach?
    !credit_card?
  end
  def bank_account_type
    return nil unless ach?
    return account_type == 'C' ? 'PC' : 'PS'
  end
  def dcas_bank_account_type
    return nil unless ach?
    return account_type == 'C' ? 'Checking' : 'Savings'
  end
  def self.merchant_id(location)
    LOCATIONS.has_key?(location) ? LOCATIONS[location][:merchant_id] : nil
  end
  def merchant_id
    LOCATIONS.has_key?(location) ? LOCATIONS[location][:merchant_id] : nil
  end
  def merchant_pin
    LOCATIONS.has_key?(location) ? LOCATIONS[location][:merchant_pin] : nil
  end
  end # Financial Information
  begin # CSV Generation
  def self.csv_headers
    ["Account ID", "First Name", "Last Name", "Bank Routing #", "Bank Account #", "Bank Account Type", "Name on Card", "Credit Card Number", "Expiration", "Amount", "Type", "Authorization", "Record", "Occurrence"]
  end
  def self.dcas_header_row(batch_id, location)
    [
      'HD',
      LOCATIONS[location][:dcas][:company_alias],
      LOCATIONS[location][:dcas][:company_user],
      LOCATIONS[location][:dcas][:company_pass],
      'Check' # Invoice/Customer/Check/Image
    ]
  end
  def to_dcas_csv_row(options={})
    # DCAS Example:
        # HD,CompanyName,UserName,Password,CHECK 
        # CA,111000753,1031103,42676345,50.99,,Darwin Rogers,1409 N AVE,,,75090,,,,,2919,,,,,Checking,,,,,,200
        # CC,VISA,4118000000981234,04/2009,19.99,N,,162078,JACLYN ,545 Sheridan Ave,,,07203,,,,9872,,,2,3,1
    ach? ? [ # This is for bank account transactions
      'CA',
      bank_routing_number,
      bank_account_number,
      get_check_number, # check number field can be used to prevent duplicates
      amount,
      nil, # invoice number
      name_on_card,
      nil, # address - API says required, but it's really not.
      nil, # city
      nil, # state
      nil, # zip
      nil, # phone number
      nil, # driver license number
      nil, # driver license state
      nil, # third party check? 1=yes, 0=no
      "#{Time.parse(batch.for_month).strftime("%y%m")}#{client_id}", # CustTraceCode
      nil, # image name
      nil, # back image name
      options[:refund] ? 'Credit' : nil, # Credit/Debit (default Debit)
      nil, # Internal Account Number: date (in 4 digits: YYMM) + client id
      dcas_bank_account_type #, nil,
      # ECC - Default Entry Class Code (??)
      # nil, nil, nil, nil, # Deposit info
      # nil, # CPA Code
      # nil, nil, # scanned MICR info
      # nil, nil # endorsement and image
    ] : [ # This is for credit card transactions
      'CC',
      dcas_card_type, # Card Type
      credit_card_number, # Account Number
      expiration.nil? ? nil : (expiration[0,2] + '/20' + expiration[2,2]), # Expiration date (MM/YYYY)
      amount, # Amount (00.00)
      'N', # Card Present
      nil, # Card verification (if present)
      nil, # invoice number
      name_on_card, # name # Larry Cummings @ DCAS Support: (972) 239-2327, ext 153 #OR# (972) 392-4654
      nil, # address
      nil, # city
      nil, # state
      nil, # zip
      nil, # phone number
      nil, # driver license number
      nil, # driver license state
      "#{Time.parse(batch.for_month).strftime("%y%m")}#{client_id}", # CustTraceCode
      options[:refund] ? 'Credit' : nil, # Credit/Debit (default Debit)
      nil,
      2,
      3,
      1,
      nil
    ]
  end

  def to_csv_row(options={})
    [
      client_id,
      first_name,
      last_name,
      ach? ? bank_routing_number : nil,
      ach? ? bank_account_number : nil,
      ach? ? bank_account_type : nil,
      name_on_card,
      credit_card_number,
      expiration,
      amount,
      tran_type,
      ach? ? authorization : nil,
      options[:refund] ? (ach? ? 'Credit' : 'Refund') : (ach? ? 'Debit' : 'Sale'),
      'Single'
    ].map {|c| c.to_csv}
  end

  def self.managers_csv_headers
    ['ClientId', 'FirstName', 'LastName', 'Amount', 'AccountType','TransactionId', 'Status', 'Messages']
  end
  def to_managers_csv_row
    [
      client_id,
      first_name,
      last_name,
      amount,
      account_type == 'C' ? 'Checking' : (account_type == 'S' ? 'Savings' : 'Charge'),
      transaction_id,
      state,
      (goto_invalid.to_a + [description]).to_sentence
    ].map {|c| c.to_csv}
  end
  end # CSV Generation
  begin # Helios Operations
  def remove_vip!
    client.remove_vip! if client
    destroy
  end
  def reload_eft!(store_name)
    # Just make it batch:
    # Touch EFT on current store
    Helios::Eft.touch_on_slave(store_name, client_id) &&
    # Touch ClientProfile on current store
    Helios::ClientProfile.touch_on_slave(store_name, client_id)
    # CHECK IF THE LAST PERSON IN MISSING EFT AT LINWAY, ZONE1 IS NOT THERE ANYMORE
  end

  def record_to_helios!
    # 1) Transaction
    #   +) Create Transaction if needed and hasn't been created
    # 2) Note
    #   +) Create Note if needed and hasn't been created
    # 3) ClientProfile
    #   +) Record previous balance in GotoTransaction
    #   +) Change balance accordingly, if applicable
    record_transaction_to_helios!
    record_note_to_helios!
    record_client_balance_to_helios!
  end
  def record_transaction_to_helios!
    return unless transaction_id.to_i == 0
    return unless paid? || declined? || cached_invalid?

    a = amount.to_s.gsub(/\./, '')
    inconvenience_charge = declined? ? 5 : 0
    amnt = ((a.chop.chop+'.'+a[-2,2]).to_f + inconvenience_charge).to_s
    trans_attrs = {
      :Descriptions => case # Needs to include certain information for different cases
        when cached_invalid?
          "#{'VIP: ' unless bank_routing_number.to_s == '123'}#{goto_invalid.to_sentence}" # routing number == 123 if person is a cash member.
        when declined?
          "Declined: ##{description}"
        when paid?
          "Payment Received"
        end[0..24],
      :client_no => client_id,
      :Last_Name => last_name,
      :First_Name => first_name,
      :CType => 'S',
      :Code => 'EFT Active',
      :Division => ZONE[:Division], # 2 for zone1
      :Department => ZONE[:Department], # 7 for zone1
      :Location => LOCATIONS.reject {|k,v| !v[:master]}.keys[0],
      :Price => amnt,
      :Check => paid? && ach? ? amnt : 0,
      :Charge => paid? && credit_card? ? amnt : 0,
      :Credit => declined? || cached_invalid? ? amnt : 0, #Tie with CP#Balance
      :Wait_For => case
        when !paid?
          'I'
        when ach?
          'K'
        when credit_card?
          'N'
        end
    }
    ot = Helios::Transact.create_on_master(trans_attrs) # Auto-touches client profile
    update_attributes(:transaction_id => ot.id) # Remembers the id of the transaction it just made in Helios
  end
  def record_note_to_helios!
    return unless note_id.to_i == 0 # We won't create a note twice...
    return unless declined? || informational? || cached_invalid? # Notes are for declines, information, or invalid records.

    message = '' # Following lines: Result can be informational regardless of declined or invalid.
    message << "EFT Declined: #{description}" if declined?
    message << "#{'Invalid EFT: ' unless bank_routing_number.to_s == '123'}#{(goto_invalid + [description]).to_sentence}" if cached_invalid?
    message << information if informational?
    note = Helios::Note.create_on_master(
      :Client_no => client_id,
      :Location => LOCATIONS.reject {|k,v| !v[:master]}.keys[0],
      :Last_Name => last_name,
      :First_Name => first_name,
      :Comments => message,
      :EmpCode => 'EC',
      :Interrupt => true,
      :Deleted => false
    )
    update_attributes(:note_id => note.id)
  end
  def record_client_balance_to_helios!
    # This method adds the amount to the client's Balance and PaymentAmount, +$5 if it had been send and declined.
    return unless declined? || cached_invalid?

    if previous_balance.blank? && previous_payment_amount.blank? # Meaning, if we haven't already incremented the client's profile.
      a = amount.to_s.gsub(/\./, '')
      inconvenience_charge = declined? ? 5 : 0
      amnt = ((a.chop.chop + '.' + a[-2,2]).to_f + inconvenience_charge).to_s

      update_attributes(:previous_balance => client.Balance.to_f, :previous_payment_amount => client.Payment_Amount.to_f)

      client.update_attributes(
        :Payment_Amount => previous_payment_amount.to_f + amnt.to_f,
        :Balance => previous_balance.to_f + amnt.to_f,
        :UpdateAll => Time.now
      )
    end
    if !recd_date_due
      if client.Date_Due != Time.gm(Time.now.year, Time.now.month, 1, 0, 0, 0)
        client.update_attributes( # For some reason we have to do it a second time sometimes for Date_Due to register.
          :Date_Due => Time.gm(Time.now.year, Time.now.month, 1, 0, 0, 0),
          :UpdateAll => Time.now
        )
      else
        update_attributes(:recd_date_due => true)
      end
    end
  end

  def revert_helios!
    revert_helios_client_profile!
    revert_helios_note!
    revert_helios_transaction!
  end
  def revert_helios_client_profile!
    # Client balance and payment_due must be reverted to their original values. Originals saved in this record.
    client.update_attributes(:Balance => previous_balance) if previous_balance
    client.update_attributes(:Payment_Amount => previous_payment_amount) if previous_payment_amount
    client.update_attributes(:UpdateAll => Time.now) if previous_balance || previous_payment_amount
    update_attributes(:recd_date_due => false)
  end
  def revert_helios_note!
    # Just delete the note
    Helios::Note.update_on_master(note_id, :Deleted => true, :Client_no => client_id) unless note_id.blank? || note_id == 0
    update_attributes(:note_id => 0)
  end
  def revert_helios_transaction!
    # Just delete the transaction and touch the client profile
    Helios::Transact.update_on_master(transaction_id, :CType => 1, :client_no => client_id) unless transaction_id.blank? || transaction_id == 0
    update_attributes(:transaction_id => 0)
  end
  end # Helios Operations
  begin # Status Methods
  # Status Codes:
  #   'R' => Received
  #   'A' => Accepted
  #   'D' => Declined
  #   'G' => Paid (Approved)
  #   'E' => Processing Error
  #  lowercase of the above denotes refund
  # Status Queries:
  #   Processing?       [R]
  #   Accepted?         [A]
  #   Declined?         [D]
  #   Paid?             [G]
  #   ProcessingError?  [E]
  def state # = GREADI :)
    {
      'G' => 'Paid',
      'R' => 'Processing',
      'E' => 'Processing Error',
      'A' => 'Accepted',
      'D' => 'Declined!',
      'I' => 'Information',
    }[status]
  end

  def processed?
    status =~ /[GDE]/
  end
  def processing?
    status == 'R'
  end
  def accepted?
    status == 'A'
  end
  def paid?
    status == 'G'
  end
  def declined?
    status == 'D'
  end
  def informational?
    !information.nil?
  end
  def process_error?
    status == 'E'
  end
  end # Status Methods
  begin # Validation
  def cached_valid?
    goto_invalid.to_a.blank?
  end
  def cached_invalid?
    !goto_invalid.to_a.blank?
  end
  def goto_is_valid?
    # Validates the record for sending to gotobilling.
    inv = []
    inv << "Expired Card" if credit_card? && expiration && Time.parse(expiration[0,2] + '/01/' + expiration[2,2]) < Time.parse(batch.for_month)
    inv << "Invalid Credit Card Number" if credit_card? && !validCreditCardNumber?(credit_card_number)
    inv << "Invalid Account Number" if ach? && !validAccountNumber?(bank_account_number.to_s)
    if !credit_card? && !validABA?(bank_routing_number.to_s)
      if bank_routing_number.to_s == '123'
        inv << "Cash VIP"
      else
        inv << "Invalid Routing Number"
      end
    end
    inv << "First/Last Name is blank" if (first_name.to_s + last_name.to_s).blank?
    inv << "Name cannot contain numbers" if first_name.to_s =~ /\d/ || last_name.to_s =~ /\d/
    if !description.blank?
      inv << description
    end
    self.goto_invalid = inv
    return goto_invalid.blank?
  end
  def goto_is_invalid?
    !goto_is_valid?
  end
  end # Validation

  def full_name
    "#{first_name} #{last_name}"
  end
  def get_check_number
    return check_number unless check_number.nil?
    # Sample: 08031 (March 2008, 1st transaction)
    batch_month_YYYYMM = batch.for_month.gsub(/\D/,'')
    # of the different transactions with the same account, this makes SURE there are NO duplicate check numbers.
    check_numbers = {}
    self.class.find(:all, :conditions => ["batch_id = ? AND bank_account_number = ?", batch_id, bank_account_number]).each do |acct|
      check_numbers[acct.check_number] = acct if acct.check_number
    end
    index = 0
    # Increment the index number if it is in the list and the item referred to in the list is NOT the current record.
    index += 1 while(check_numbers.has_key?("#{batch_month_YYYYMM}#{index}") && check_numbers["#{batch_month_YYYYMM}#{index}"].id != id)
    self.check_number = "#{batch_month_YYYYMM}#{index}"
    # save # To make sure this check number doesn't get conflicted with.
  end

  private
    def validate
      errors.add_to_base("Invalid Location Code!") if !LOCATIONS.has_key?(location)
    end
    def validABA?(aba)
      # 1) Check for all-numbers.
      # 2) Check length == 9
      # 3) Total of all digits (each multiplied by 3, 7 or 1 in cycle) should % 10
      i = 2
      aba.to_s.gsub(/\D/,'').length == 9 && aba.to_s.gsub(/\D/,'').split('').map {|d| d.to_i*[3,7,1][i=i.cyclical_add(1,0..2)] }.sum % 10 == 0
    end
    def validCreditCardNumber?(ccn)
  # 1) MOD 10 check
      odd = true
      ccn.to_s.gsub(/\D/,'').reverse.split('').map(&:to_i).collect { |d|
        d *= 2 if odd = !odd
        d > 9 ? d - 9 : d
      }.sum % 10 == 0 &&

  # 2) Card Prefix Check -X- We don't store the credit card type, so we can't perform this check.
      true &&

  # 3) Card Length Check -X- We don't store the credit card type, so we can't perform this check.
      true
    end
    def validAccountNumber?(act)
      act.length < 18
    end
end
