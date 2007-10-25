class GotoTransaction < GotoBilling::Base
  self.site = 'https://www.gotobilling.com/os/system/gateway/transact.php'

  def initialize(attrs={})
    if(attrs.is_a?(Helios::Eft))
      location_code = attrs.Location || '0'*(3-ZONE_LOCATION_BITS)+attrs.Client_No.to_s[0,ZONE_LOCATION_BITS]
      amount_int = (attrs.Monthly_Fee.to_f*100).to_i

      super(
        :account_id => attrs.id.to_i,
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
    new(
      :account_id => row[0],
      :first_name => row[1],
      :merchant_id => row[2],
      :merchant_pin => LOCATIONS[LOCATIONS.reject {|k,v| LOCATIONS[k][:merchant_id] != row[2]}.keys[0]][:merchant_pin],
      :last_name => row[3],
      :bank_routing_number => row[4],
      :bank_account_number => row[5],
      :name_on_card => row[6],
      :credit_card_number => row[7],
      :expiration => row[8],
      :amount => row[9],
      :type => row[10],
      :account_type => row[11],
      :authorization => row[12]
    )
  end

  def to_a
    [
      account_id,
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
      authorization
    ]
  end

  def self.http_attribute_mapping
    {
      'account_id' => 'x_customer_id',
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
      'account_id' => lambda {|x| x},
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
      'merchant_pin' => lambda {|x| x}
    }[attr_name.to_s].call(@attributes[attr_name.to_s])
  end

  has_attributes :account_id, :first_name, :last_name, :bank_routing_number, :bank_account_number, :name_on_card, :credit_card_number, :expiration, :amount, :type, :account_type, :authorization, :merchant_id, :merchant_pin
  validates_presence_of :account_id, :first_name, :last_name, :amount, :type, :account_type, :authorization, :merchant_id, :merchant_pin
  validates_presence_of :bank_routing_number, :bank_account_number, :if => :ach?
  validates_presence_of :name_on_card, :credit_card_number, :expiration, :if => :credit_card?

  def validate
    # errors.add_to_base("Expired Card") if credit_card? && Time.parse(expiration[0,2] + '/01/' + expiration[2,2]) < (Time.now+1.day).beginning_of_day
    errors.add_to_base("Invalid Credit Card Number") if credit_card? && !validCreditCardNumber?(credit_card_number)
    errors.add_to_base("Invalid Routing Number") if !credit_card? && !bank_routing_number.blank? && !validABA?(bank_routing_number)
  end

  def credit_card?
    !['C','S'].include?(@attributes['account_type'])
  end
  def ach?
    !credit_card?
  end
  def account_type=(value)
    return if value.blank?
    raise GotoBilling::AttributeError, "AccountType (got #{value}) can only be A, C, I, M, S or V." unless ['A','C','I','M','S','V'].include?(value)
    @attributes['account_type'] = value
  end
  def authorization=(value)
    return if value.blank?
    raise GotoBilling::AttributeError, "Authorization (got #{value}) can only be Written, Tel, or Web." unless ['Written', 'Tel', 'Web'].include?(value)
    @attributes['authorization'] = value
  end
  def type=(value)
    return if value.blank?
    raise GotoBilling::AttributeError, "Type (got #{value}) can only be ACH or Credit Card." unless ['ACH', 'Credit Card'].include?(value)
    @attributes['type'] = value
  end
  def expiration=(value)
    return if value.blank?
    raise GotoBilling::AttributeError, "Expiration (got #{value}) should be a string containing 4 numbers, representing MM and YY." unless value.gsub(/\D/,'').length == 4
    @attributes['expiration'] = value.gsub(/\D/,'')
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
