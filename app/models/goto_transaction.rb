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
  serialize :goto_invalid, Array

  is_searchable :by_query => 'goto_transactions.first_name LIKE :like_query OR goto_transactions.last_name LIKE :like_query OR goto_transactions.credit_card_number LIKE :like_query OR goto_transactions.bank_account_number LIKE :like_query',
    :filters => {
      'has_eft' => '(goto_transactions.no_eft != ? OR goto_transactions.no_eft IS NULL)', # Should be a 1
      'no_eft' => 'goto_transactions.no_eft = ?', # Should be a 1
      'goto_invalid' => '(goto_transactions.goto_invalid IS NOT NULL AND NOT(goto_transactions.goto_invalid LIKE ?))',
      'goto_valid' => '(goto_transactions.goto_invalid IS NULL OR goto_transactions.goto_invalid LIKE ?)',
      'batch_id' => 'goto_transactions.batch_id = ?'
    }

  def initialize(attrs={})
    attrs = {} if attrs.nil?
    if(attrs.is_a?(Helios::Eft))
      location_code = attrs.Location || '0'*(3-ZONE_LOCATION_BITS)+attrs.Client_No.to_s[0,ZONE_LOCATION_BITS]
      amount_int = attrs.Monthly_Fee.to_f.to_s
    
      super(
        :client_id => attrs.id.to_i,
        :location => location_code,
        :first_name => attrs.First_Name,
        :last_name => attrs.Last_Name,
        :bank_routing_number => attrs.Bank_ABA,
        :bank_account_number => attrs.credit_card? ? nil : attrs.Acct_No,
        :name_on_card => attrs.First_Name.to_s + ' ' + attrs.Last_Name.to_s,
        :credit_card_number => attrs.credit_card? ? attrs.Acct_No : nil,
        :expiration => attrs.Acct_Exp.to_s.gsub(/\D/,''),
        :amount => amount_int,
        :type => attrs.credit_card? ? 'Credit Card' : 'ACH',
        :account_type => attrs.Acct_Type,
        :authorization => 'Written'
      )

      # Pretend we're the already-made batch if one for this month already exists
      if exis = self.class.find_by_client_id(self.client_id)
        self.id = exis.id
        @new_record = false
      end
    else
      super(attrs)
    end
  end

  def goto_is_valid?
    # Validates the record for sending to gotobilling.
    self.goto_invalid = [1]
    self.goto_invalid << "Expired Card" if credit_card? && Time.parse(expiration[0,2] + '/01/' + expiration[2,2]) < Time.parse(self.batch.for_month)
    self.goto_invalid << "Invalid Credit Card Number" if credit_card? && !validCreditCardNumber?(credit_card_number)
    if !credit_card? && !bank_routing_number.blank? && !validABA?(bank_routing_number)
      if bank_routing_number.to_s == '123'
        self.goto_invalid << "Cash VIP"
      else
        self.goto_invalid << "Invalid Routing Number"
      end
    end
    self.goto_invalid.shift
    return self.goto_invalid.nil?
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
