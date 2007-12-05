class GotoResponse
  include CoresExtensions
  attr_accessor :merchant_id, :first_name, :last_name, :status, :client_id, :order_number, :term_code, :amount, :sent_date, :tran_date, :tran_time, :invoice_id, :auth_code, :description

  def attributes
    at = {}
    self.instance_variables.each do |iv|
      iv.gsub!('@', '')
      at[iv] = self.instance_variable_get("@#{iv}")
    end
    at
  end

  def attributes=(new_attributes)
    return if new_attributes.nil?
    with(new_attributes.dup) do |a|
      a.stringify_keys!
      a.each {|k,v| send(k + "=", a.delete(k)) if self.respond_to?("#{k}=")}
    end
  end

  def initialize(attrs={}) # From csv row, or from xml-hash
    new_attrs = {}
    nattrs = attrs.dup
    if nattrs.is_a?(Hash) # Is xml-hash
      nattrs.stringify_keys!
      # status, order_number, term_code, tran_amount, tran_date, tran_time, invoice_id, auth_code, description
      new_attrs = nattrs
    elsif nattrs.respond_to?('[]') # Is csv row
      # MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,Status,Description
      new_attrs = {
        :status       => nattrs[8],
        :client_id    => nattrs[3],
        :merchant_id  => nattrs[0],
        :first_name   => nattrs[1],
        :last_name    => nattrs[2],
        :order_number => nattrs[7],
        :term_code    => nil,
        :tran_amount  => nattrs[4],
        :sent_date    => nattrs[5],
        :tran_date    => nattrs[6],
        :tran_time    => nattrs[6],
        :invoice_id   => nil,
        :auth_code    => nil,
        :description  => nattrs[9]
      }
    end
    self.attributes = new_attrs
    self
  end

  alias :tran_amount :amount
  alias :tran_amount= :amount=
  alias :transaction_id :invoice_id
  alias :transaction_id= :invoice_id=

  def valid?
    return true
  end
end
