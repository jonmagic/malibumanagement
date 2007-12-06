# # Recorded bits
# t.column :no_eft,               :boolean
# t.column :goto_invalid,         :string
# t.column :transaction_id,       :integer # OTNum field
# t.column :note_id,              :integer # OTNum field
# t.column :recorded,             :boolean
# # Response attributes, :string
# t.column :order_number, :string
# t.column :sent_date,    :string
# t.column :tran_date,    :string
# t.column :tran_time,    :string
# t.column :status,       :string
# t.column :description,  :string
# t.column :term_code,    :string
# t.column :auth_code,    :string
class GotoTransaction < ActiveRecord::Base
  @nologging = true

  belongs_to :batch, :class_name => 'EftBatch', :foreign_key => 'batch_id'
  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_id'
  belongs_to :eft, :class_name => 'Helios::Eft', :foreign_key => 'client_id'

  serialize :goto_invalid, Array

  is_searchable :by_query => 'goto_transactions.first_name LIKE :like_query OR goto_transactions.last_name LIKE :like_query OR goto_transactions.credit_card_number LIKE :like_query OR goto_transactions.bank_account_number LIKE :like_query OR goto_transactions.client_id = :query',
    :and_filters => {
      'has_eft' => '(goto_transactions.no_eft != ? OR goto_transactions.no_eft IS NULL)', # Should be a 1
      'no_eft' => 'goto_transactions.no_eft = ?', # Should be a 1
      'goto_invalid' => '(goto_transactions.goto_invalid IS NOT NULL AND NOT(goto_transactions.goto_invalid LIKE ?))',
      'goto_valid' => '(goto_transactions.goto_invalid IS NULL OR goto_transactions.goto_invalid LIKE ?)',
      'batch_id' => 'goto_transactions.batch_id = ?',
      'location' => 'goto_transactions.location = ?',
      'amount' => 'goto_transactions.amount = ?'
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
          :last_name => cp.Last_Name
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

    # With only {attributes} at this point, make sure we're not duplicating records.
    if exis = self.class.find_by_batch_id_and_client_id(attrs[:batch_id], attrs[:client_id])
      super(exis.attributes.merge(attrs))
      self.id = exis.id
      @new_record = false
    else
      super(attrs)
    end
    # Refresh the invalid status field
    self.goto_is_valid?
  end

  def goto_is_valid?
    # Validates the record for sending to gotobilling.
    inv = []
    inv << "Expired Card" if credit_card? && expiration && Time.parse(expiration[0,2] + '/01/' + expiration[2,2]) < Time.parse(self.batch.for_month)
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
    return self.goto_invalid.blank?
  end
  def goto_is_invalid?
    !goto_is_valid?
  end

  def full_name
    self.first_name.to_s + ' ' + self.last_name.to_s
  end
  def credit_card?
    !['C','S'].include?(self.account_type)
  end
  def ach?
    !credit_card?
  end
  def merchant_id
    LOCATIONS.has_key?(location) ? LOCATIONS[location][:merchant_id] : nil
  end
  def merchant_pin
    LOCATIONS.has_key?(location) ? LOCATIONS[location][:merchant_pin] : nil
  end

  def remove_vip!(store_name)
    self.client.remove_vip!(store_name) if self.client
    self.destroy
  end

  def reload_eft!(store_name)
    # Just make it batch:
    # Touch EFT on current store
    Helios::Eft.touch_on_slave(store_name, self.client_id) &&
    # Touch ClientProfile on current store
    Helios::ClientProfile.touch_on_slave(store_name, self.client_id)
    # CHECK IF THE LAST PERSON IN MISSING EFT AT LINWAY, ZONE1 IS NOT THERE ANYMORE
  end

  def self.csv_headers
    ["Account ID", "First Name", "Last Name", "Bank Routing #", "Bank Account #", "Name on Card", "Credit Card Number", "Expiration", "Amount", "Type", "Authorization", "Record", "Occurrence"]
  end
  def to_csv_row
    [
      client_id,
      first_name,
      last_name,
      bank_routing_number,
      bank_account_number,
      name_on_card,
      credit_card_number,
      expiration,
      amount,
      tran_type,
      ach? ? authorization : nil,
      ach? ? 'Debit' : 'Sale',
      'Single'
    ].map {|c| c.to_csv}
  end

  def self.managers_csv_headers
    ['ClientId', 'FirstName', 'LastName', 'Amount', 'TransactionId', 'Status', 'Messages']
  end
  def to_managers_csv_row
    [
      client_id,
      first_name,
      last_name,
      amount,
      transaction_id,
      {'G' => 'Paid', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[status],
      goto_invalid.to_sentence
    ].map {|c| c.to_csv}
  end

  def record_to_helios!
    # 1) Transaction
    #   +) If transaction exists
    #     -) EDIT transaction
    #   +) If transaction doesn't exist
    #     -) CREATE transaction
    # 2) Note
    #   +) If exist and shouldn't, remove
    #   +) If don't exist and should, create
    # 3) ClientProfile
    #   +) Record previous balance in GotoTransaction
    #   +) Change balance accordingly, if applicable

    # puts "Recording transaction"
    self.record_transaction_to_helios!
    # puts "Recording note" if self.declined? || !self.goto_invalid.to_a.blank?
    self.record_note_to_helios! if self.declined? || !self.goto_invalid.to_a.blank?
    # puts "Recording balance" if self.declined? || !self.goto_invalid.to_a.blank?
    self.record_client_profile_to_helios! if self.declined? || !self.goto_invalid.to_a.blank?
  end
  def record_client_profile_to_helios!
    if self.declined? || !self.goto_invalid.to_a.blank?
      if self.previous_balance.blank? && self.previous_payment_amount.blank?
        a = self.amount.to_s.split(/\./).join('')
        amnt = a.chop.chop+'.'+a[-2,2]

        self.update_attributes(:previous_balance => self.client.Balance.to_f, :previous_payment_amount => self.client.Payment_Amount.to_f)

        self.client.update_attributes(
          :Payment_Amount => (self.previous_payment_amount.to_f + amnt.to_f + (self.submitted? ? 5 : 0)),
          :Balance => self.previous_balance.to_f + amnt.to_f + (self.submitted? ? 5 : 0),
          :UpdateAll => Time.now
        )
      end
      if !self.recd_date_due
        if self.client.Date_Due != Time.gm(Time.now.year, Time.now.month, 1, 0, 0, 0)
          self.client.update_attributes( # For some reason we have to do it a second time for Date_Due to register.
            :Date_Due => Time.gm(Time.now.year, Time.now.month, 1, 0, 0, 0),
            :UpdateAll => Time.now
          )
        else
          self.update_attributes(:recd_date_due => true)
        end
      end
    else
      # Nothing to edit in ClientProfile if not invalid or declined.
    end
  end
  def record_note_to_helios!
    # Create a transaction on the master, touch the client profile, and set transaction_id = master_record.transact_no
    if self.declined? || !self.goto_invalid.to_a.blank?
      if self.note_id.nil?
        note = Helios::Note.create_on_master(
          :Client_no => self.client_id,
          :Location => LOCATIONS.reject {|k,v| !v[:master]}.keys[0],
          :Last_Name => self.last_name,
          :First_Name => self.first_name,
          :Comments => !self.goto_invalid.to_a.blank? ? "#{'Invalid EFT: ' unless self.bank_routing_number.to_s == '123'}#{self.goto_invalid.to_sentence}" : "EFT Declined: #{self.description}",
          :EmpCode => 'EC',
          :Interrupt => true,
          :Deleted => false
        )
        self.update_attributes(:note_id => note.id)
      else
        # CURRENTLY DOES NOTHING IF THE NOTE ID IS ALREADY SET!!
        # Update the current note?
      end
    end
  end
  def record_transaction_to_helios!
    # Create a transaction on the master, touch the client profile, and set transaction_id = master_record.transact_no
    if self.transaction_id.nil?
      a = self.amount.to_s.split(/\./).join('')
      amnt = a.chop.chop+'.'+a[-2,2]
      trans_attrs = {
        :Descriptions => case # Needs to include certain information for different cases
          when !self.goto_invalid.to_a.blank?
            "#{'VIP: ' unless self.bank_routing_number.to_s == '123'}#{self.goto_invalid.to_sentence}"
          when self.declined?
            "Declined: ##{self.description}"
          else
            "Accepted"
          end[0..24],
        :client_no => self.client_id,
        :Last_Name => self.last_name,
        :First_Name => self.first_name,
        :CType => 'S',
        :Code => 'EFT Active',
        :Division => ZONE[:Division], # 2 for zone1
        :Department => ZONE[:Department], # 7 for zone1
        :Location => LOCATIONS.reject {|k,v| !v[:master]}.keys[0],
        :Price => amnt,
        :Check => self.paid? && self.ach? ? amnt : 0,
        :Charge => self.paid? && self.credit_card? ? amnt : 0,
        :Credit => self.declined? || !self.goto_invalid.to_a.blank? ? amnt : 0, #Tie with CP#Balance
        :Wait_For => case
          when self.declined? || !self.goto_invalid.to_a.blank?
            'I'
          when self.ach?
            'K'
          when self.credit_card?
            'N'
          end
      }
      ot = Helios::Transact.create_on_master(trans_attrs) # Auto-touches client profile

      self.update_attributes(:transaction_id => ot.id)
    else
      # CURRENTLY DOES NOTHING IF THE TRANSACTION ID IS ALREADY SET!!
      # Update the current transaction?
    end
  end

 # Status checking methods
  def submitted?
    !self.status.blank?
  end
  def declined?
    self.status == 'D'
  end
  def paid?
    self.status == 'G'
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

  # def self.http_attribute_mapping
  #   {
  #     'client_id' => 'x_customer_id',
  #     'merchant_id' => 'merchant_id',
  #     'merchant_pin' => 'merchant_pin',
  #     'last_name' => 'x_last_name',
  #     'first_name' => 'x_first_name',
  #     'tran_type' => 'x_transaction_type',
  #     'transaction_id' => 'x_invoice_id',
  #     'amount' => 'x_amount',
  #     'authorization' => 'x_ach_payment_type',
  #     'bank_routing_number' => 'x_ach_route',
  #     'bank_account_number' => 'x_ach_account',
  #     'account_type' => 'x_ach_account_type',
  #     'name_on_card' => 'x_cc_name',
  #     'credit_card_number' => 'x_cc_number',
  #     'expiration' => 'x_cc_exp'
  #   }
  # end
  # 
  # def http_attribute_convert(attr_name)
  #   {
  #     'client_id' => lambda {|x| x},
  #     'last_name' => lambda {|x| x},
  #     'first_name' => lambda {|x| x},
  #     'tran_type' => lambda {|x| {'ACH' => 'DH', 'Credit Card' => 'ES'}[x]},
  #     'transaction_id' => lambda {|x| x},
  #     'amount' => lambda {|x| x},
  #     'authorization' => lambda {|x| {'Written' => 'PPD', 'Tel' => 'TEL', 'Web' => 'WEB'}[x]},
  #     'bank_routing_number' => lambda {|x| x},
  #     'bank_account_number' => lambda {|x| x},
  #     'account_type' => lambda {|x| self.tran_type == 'ACH' ? {'C' => 'PC', 'S' => 'PS'}[x] : nil},
  #     'name_on_card' => lambda {|x| x},
  #     'credit_card_number' => lambda {|x| x},
  #     'expiration' => lambda {|x| x},
  #     'merchant_id' => lambda {|x| x},
  #     'merchant_pin' => lambda {|x| x},
  #     'location' => lambda {nil},
  #     'transaction_id' => lambda {|x| x}
  #   }[attr_name.to_s].call(@attributes[attr_name.to_s])
  # end
end
