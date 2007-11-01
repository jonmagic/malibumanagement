class GotoTransaction < GotoBilling::Base
  self.site = 'https://www.gotobilling.com/os/system/gateway/transact.php'

  def self.headers
    ["ClientId", "Location", "MerchantId", "FirstName", "LastName", "BankRoutingNumber", "BankAccountNumber", "NameOnCard", "CreditCardNumber", "Expiration", "Amount", "Type", "AccountType", "Authorization", "TransactionId", "Recorded", "OrderNumber", "SentDate", "TranDate", "TranTime", "Status", "Description", "TermCode", "AuthCode"]
  end

  def initialize(attrs={})
    if(attrs.is_a?(Helios::Eft))
      location_code = attrs.Location || '0'*(3-ZONE_LOCATION_BITS)+attrs.Client_No.to_s[0,ZONE_LOCATION_BITS]
      amount_int = (attrs.Monthly_Fee.to_f.to_s.split(/\./).join('')).to_i
    
      super(
        :client_id => attrs.id.to_i,
        :location => location_code,
        :merchant_id => LOCATIONS.has_key?(location_code.to_s) ? LOCATIONS[location_code.to_s][:merchant_id] : nil,
        :merchant_pin => LOCATIONS.has_key?(location_code.to_s) ? LOCATIONS[location_code.to_s][:merchant_pin] : nil,
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
      errors.add_to_base("Invalid Location Code!") if !LOCATIONS.has_key?(location_code.to_s)
    else
      super(attrs)
    end
  end

  def self.new_from_csv_row(row)
    i = -1
# client_id, location, merchant_id, merchant_pin, first_name, last_name, bank_routing_number, bank_account_number, name_on_card, credit_card_number, expiration, amount, type, account_type, authorization, transaction_id, recorded, order_number, sent_date, tran_date, tran_time, status, description, term_code, auth_code
    new(
      :client_id => row[i+=1],
      :location => row[i+=1],
      :merchant_id => row[i+=1],
      :merchant_pin => LOCATIONS[row[1]][:merchant_pin],
      :first_name => row[i+=1],
      :last_name => row[i+=1],
      :bank_routing_number => row[i+=1],
      :bank_account_number => row[i+=1],
      :name_on_card => row[i+=1],
      :credit_card_number => row[i+=1],
      :expiration => row[i+=1],
      :amount => row[i+=1],
      :type => row[i+=1],
      :account_type => row[i+=1],
      :authorization => row[i+=1],
      :transaction_id => row[i+=1],
      :recorded => row[i+=1],
    # Response attributes
      :order_number => row[i+=1],
      :sent_date => row[i+=1],
      :tran_date => row[i+=1],
      :tran_time => row[i+=1],
      :status => row[i+=1],
      :description => row[i+=1],
      :term_code => row[i+=1],
      :auth_code => row[i+=1]
    )
  end

  def to_a
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

  def self.managers_headers
    ['ClientId', 'FirstName', 'LastName', 'Amount', 'TransactionId', 'Status', 'Description']
  end
  def to_managers_a
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

  has_attributes :client_id, :location, :merchant_id, :merchant_pin, :first_name, :last_name, :bank_routing_number, :bank_account_number, :name_on_card, :credit_card_number, :expiration, :amount, :type, :account_type, :authorization, :transaction_id, :recorded, :order_number, :sent_date, :tran_date, :tran_time, :status, :description, :term_code, :auth_code
  validates_presence_of :client_id, :first_name, :last_name, :amount, :type, :account_type, :authorization, :merchant_id, :merchant_pin
  validates_presence_of :bank_routing_number, :bank_account_number, :if => :ach?
  validates_presence_of :name_on_card, :credit_card_number, :expiration, :if => :credit_card?

  def validate
    # errors.add_to_base("Expired Card") if credit_card? && Time.parse(expiration[0,2] + '/01/' + expiration[2,2]) < (Time.now+1.day).beginning_of_day
    errors.add_to_base("Invalid Credit Card Number") if credit_card? && !validCreditCardNumber?(credit_card_number)
    if !credit_card? && !bank_routing_number.blank? && !validABA?(bank_routing_number)
      if bank_routing_number.to_s == '123'
        errors.add_to_base("Cash VIP")
      else
        errors.add_to_base("Invalid Routing Number")
      end
    end
  end

  def recorded?
    @recorded
  end
  def recorded=(v)
    @recorded = (v == 'true' || v == 1 ? true : false)
  end
  def credit_card?
    !['C','S'].include?(@attributes['account_type'])
  end
  def ach?
    !credit_card?
  end
  def account_type=(value)
    return if value.blank?
    # raise GotoBilling::AttributeError, "AccountType (got #{value}) can only be A, C, I, M, S or V." unless ['A','C','I','M','S','V'].include?(value)
    if ['A','C','I','M','S','V'].include?(value)
      @attributes['account_type'] = value
    end
    @attributes['account_type']
  end
  def authorization=(value)
    return if value.blank?
    # raise GotoBilling::AttributeError, "Authorization (got #{value}) can only be Written, Tel, or Web." unless ['Written', 'Tel', 'Web'].include?(value)
    if ['Written', 'Tel', 'Web'].include?(value)
      @attributes['authorization'] = value
    end
    @attributes['authorization']
  end
  def type=(value)
    return if value.blank?
    # raise GotoBilling::AttributeError, "Type (got #{value}) can only be ACH or Credit Card." unless ['ACH', 'Credit Card'].include?(value)
    if ['ACH', 'Credit Card'].include?(value)
      @attributes['type'] = value
    end
    @attributes['type']
  end
  def expiration=(value)
    return if value.blank?
    # raise GotoBilling::AttributeError, "Expiration (got #{value}) should be a string containing 4 numbers, representing MM and YY." unless value.gsub(/\D/,'').length == 4
    if value.gsub(/\D/,'').length == 4
      @attributes['expiration'] = value.gsub(/\D/,'')
    end
    @attributes['expiration']
  end

  private
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

# Acct_Type
# A => American Express
# C => Checking
# I => Discover
# M => Mastercard
# S => Savings
# V => Visa

# total == 9315
# A == exp:70,   noexp:0,    aba:0 (70)
# C == exp:28,   noexp:3274, aba:3267 (35)
# I == exp:162,  noexp:0,    aba:7 (155)
# M == exp:2192, noexp:0,    aba:31 (2161)
# S == exp:5,    noexp:997,  aba:965 (37)
# V == exp:2586, noexp:0,    aba:17 (2569)
