class Transaction < GotoBilling::Base
  self.site = 'https://www.gotobilling.com/os/system/gateway/transact.php'

  def self.http_attribute_mapping
    {
      'account_id' => 'x_customer_id',
      'last_name' => 'x_last_name',
      'first_name' => 'x_first_name',
      'type' => 'x_transaction_type',
      'transaction_id' => 'x_invoice_id',
      'amount' => 'x_amount',
      'authorization' => 'x_ach_payment_type',
      'bank_name' => 'x_bank_name',
      'bank_routing_number' => 'x_ach_route',
      'bank_account_number' => 'x_ach_account',
      'account_type' => 'x_ach_account_type',
      'name_on_card' => 'x_cc_name',
      'credit_card_number' => 'x_cc_number',
      'expiration' => 'x_cc_exp'
    }
  end

  # require 'init'
  # t1 = Transaction.new(:account_id => 1000399, :first_name => 'JILL', :last_name => 'CHAMBERLAIN', :name_on_card => 'JILL CHAMBERLAIN', :credit_card_number => '5508635740256317', :expiration => '05/09', :amount => '18.88', :type => 'Credit Card')
  # a = t1.submit
  # t2 = Transaction.new(:account_id => 1000403, :first_name => 'Linda K', :last_name => 'Hart', :bank_name => 'american one federal', :bank_routing_number => '272481567', :bank_account_number => '1810012354203', :name_on_card => 'Linda K Hart', :amount => '18.88', :type => 'ACH', :authorization => 'Written')
  # b = t2.submit

  def http_attribute_convert(attr_name)
    {
      'account_id' => lambda {|x| x},
      'last_name' => lambda {|x| x},
      'first_name' => lambda {|x| x},
      'type' => lambda {|x| {'ACH' => 'DH', 'Credit Card' => 'ES'}[x]},
      'transaction_id' => lambda {|x| x},
      'amount' => lambda {|x| x},
      'authorization' => lambda {|x| {'Written' => 'PPD', 'Tel' => 'TEL', 'Web' => 'WEB'}[x]},
      'bank_name' => lambda {|x| x},
      'bank_routing_number' => lambda {|x| x},
      'bank_account_number' => lambda {|x| x},
      'account_type' => lambda {|x| self.type == 'ACH' ? {'C' => 'PC', 'S' => 'PS'}[x] : nil},
      'name_on_card' => lambda {|x| x},
      'credit_card_number' => lambda {|x| x},
      'expiration' => lambda {|x| x}
    }[attr_name.to_s].call(@attributes[attr_name.to_s])
  end

  has_attributes :account_id, :first_name, :last_name, :bank_name, :bank_routing_number, :bank_account_number, :name_on_card, :credit_card_number, :expiration, :amount, :type, :account_type, :authorization
  validates_presence_of :account_id, :first_name, :last_name, :amount, :type, :account_type, :authorization
  validates_presence_of :either => [:bank_name, :bank_routing_number, :bank_account_number], :or => [:name_on_card, :credit_card_number, :expiration]

  def account_type=(value)
    raise GotoBilling::AttributeError, "AccountType can only be A, C, I, M, S or V." unless ['A','C','I','M','S','V'].include?(value)
    @attributes['account_type'] = value
  end
  def authorization=(value)
    raise GotoBilling::AttributeError, "Authorization can only be Written, Tel, or Web." unless ['Written', 'Tel', 'Web'].include?(value)
    @attributes['authorization'] = value
  end
  def type=(value)
    raise GotoBilling::AttributeError, "Type can only be ACH or Credit Card." unless ['ACH', 'Credit Card'].include?(value)
    @attributes['type'] = value
  end
  def expiration=(value)
    raise GotoBilling::AttributeError, "Expiration should be a string containing 4 numbers, representing MM and YY." unless value.gsub(/\D/,'').length == 4
    @attributes['expiration'] = value.gsub(/\D/,'')
  end
end
