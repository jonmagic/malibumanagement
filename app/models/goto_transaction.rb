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
  serialize :goto_invalid, Array

  is_searchable :by_query => 'goto_transactions.first_name LIKE :like_query OR goto_transactions.last_name LIKE :like_query OR goto_transactions.credit_card_number LIKE :like_query OR goto_transactions.bank_account_number LIKE :like_query OR goto_transactions.client_id = :query',
    :and_filters => {
      'has_eft' => '(goto_transactions.no_eft != ? OR goto_transactions.no_eft IS NULL)', # Should be a 1
      'no_eft' => 'goto_transactions.no_eft = ?', # Should be a 1
      'goto_invalid' => '(goto_transactions.goto_invalid IS NOT NULL AND NOT(goto_transactions.goto_invalid LIKE ?))',
      'goto_valid' => '(goto_transactions.goto_invalid IS NULL OR goto_transactions.goto_invalid LIKE ?)',
      'batch_id' => 'goto_transactions.batch_id = ?',
      'location' => 'goto_transactions.location = ?'
    }

  #Give me:
  #batch_id, cp
  #batch_id, eft
  #or just {attributes}
  def initialize(*attrs)
    attrs = {} if attrs.blank?
    # If we're looking at a cp, change the attrs to look at it's eft, or simple attributes if no eft.
    if(attrs[1].is_a?(Helios::ClientProfile))
      batch_id = attrs[0]
      cp = attrs[1]
      # If there is no eft, turn straight into {attributes}
      if(cp.eft.nil?)
        location_code = '0'*(3-ZONE_LOCATION_BITS)+cp.id.to_s[0,ZONE_LOCATION_BITS]
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
      location_code = eft.Location || '0'*(3-ZONE_LOCATION_BITS)+eft.Client_No.to_s[0,ZONE_LOCATION_BITS]
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
        :type => eft.credit_card? ? 'Credit Card' : 'ACH',
        :account_type => eft.Acct_Type,
        :authorization => 'Written'
      }
    else
      attrs = attrs.shift
    end

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
    if !credit_card? && !bank_routing_number.blank? && !validABA?(bank_routing_number)
      if bank_routing_number.to_s == '123'
        inv << "Cash VIP"
      else
        inv << "Invalid Routing Number"
      end
    end
    self.goto_invalid = inv
    return self.goto_invalid.blank?
  end
  def goto_is_invalid?
    !goto_is_valid?
  end

  def self.http_attribute_mapping
    {
      'client_id' => 'x_customer_id',
      'merchant_id' => 'merchant_id',
      'merchant_pin' => 'merchant_pin',
      'last_name' => 'x_last_name',
      'first_name' => 'x_first_name',
      'type' => 'x_transaction_type',
      'transaction_id' => 'x_invoice_id',
      'amount' => 'x_amount',
      'authorization' => 'x_ach_payment_type',
      'bank_routing_number' => 'x_ach_route',
      'bank_account_number' => 'x_ach_account',
      'account_type' => 'x_ach_account_type',
      'name_on_card' => 'x_cc_name',
      'credit_card_number' => 'x_cc_number',
      'expiration' => 'x_cc_exp'
    }
  end

  def http_attribute_convert(attr_name)
    {
      'client_id' => lambda {|x| x},
      'last_name' => lambda {|x| x},
      'first_name' => lambda {|x| x},
      'type' => lambda {|x| {'ACH' => 'DH', 'Credit Card' => 'ES'}[x]},
      'transaction_id' => lambda {|x| x},
      'amount' => lambda {|x| x},
      'authorization' => lambda {|x| {'Written' => 'PPD', 'Tel' => 'TEL', 'Web' => 'WEB'}[x]},
      'bank_routing_number' => lambda {|x| x},
      'bank_account_number' => lambda {|x| x},
      'account_type' => lambda {|x| self.type == 'ACH' ? {'C' => 'PC', 'S' => 'PS'}[x] : nil},
      'name_on_card' => lambda {|x| x},
      'credit_card_number' => lambda {|x| x},
      'expiration' => lambda {|x| x},
      'merchant_id' => lambda {|x| x},
      'merchant_pin' => lambda {|x| x},
      'location' => lambda {nil},
      'transaction_id' => lambda {|x| x}
    }[attr_name.to_s].call(@attributes[attr_name.to_s])
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

  def remove_vip!
    #take out the vip from the client profile and destroy the eft
    self.client.remove_vip! if self.client
    self.destroy
  end

  def reload_eft!
    self.client.eft.destroy if self.client && self.client.eft
    self.client.eft = Helios::Eft.new(Helios::Eft.master[Helios::Eft.master.keys[0]].find(self.client_id).attributes) if self.client
  end

  def self.csv_headers
    ["ClientId", "Location", "MerchantId", "FirstName", "LastName", "BankRoutingNumber", "BankAccountNumber", "NameOnCard", "CreditCardNumber", "Expiration", "Amount", "Type", "AccountType", "Authorization", "TransactionId", "Recorded", "OrderNumber", "SentDate", "TranDate", "TranTime", "Status", "Description", "TermCode", "AuthCode"]
  end
  def to_csv_row
# client_id, location, merchant_id, first_name, last_name, bank_routing_number, bank_account_number, name_on_card, credit_card_number, expiration, amount, type, account_type, authorization, transaction_id, recorded, order_number, sent_date, tran_date, tran_time, status, description, term_code, auth_code
    [
      client_id,
      location,
      merchant_id,
      first_name,
      last_name,
      bank_routing_number,
      bank_account_number,
      name_on_card,
      credit_card_number,
      expiration,
      amount,
      type,
      account_type,
      authorization,
      transaction_id,
      recorded?,
      order_number,
      sent_date,
      tran_date,
      tran_time,
      status,
      description,
      term_code,
      auth_code
    ]
  end

  def self.managers_csv_headers
    ['ClientId', 'FirstName', 'LastName', 'Amount', 'TransactionId', 'Status', 'Description']
  end
  def to_managers_csv_row
    [
      client_id,
      first_name,
      last_name,
      amount,
      transaction_id,
      {'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[status],
      description
    ]
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
end
