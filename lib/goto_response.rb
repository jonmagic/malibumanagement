class GotoResponse
  include CoresExtensions
  attr_accessor :merchant_id, :first_name, :last_name, :status, :client_id, :order_number, :amount, :sent_date, :transacted_at, :transaction_id, :auth_code, :description
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
  def client
    @client ||= GotoTransaction.find_by_client_id(self.client_id)
  end
  def initialize(attrs={}) # From csv row, or from xml-hash
    new_attrs = {}
    nattrs = attrs.dup
    if nattrs.is_a?(Hash) # Is xml-hash
      nattrs.stringify_keys!
      # status, order_number, transacted_at, transaction_id, description
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
        :amount       => nattrs[4],
        :sent_date    => nattrs[5],
        :transacted_at => nattrs[6],
        :transaction_id => nattrs[7],
        :auth_code    => nil,
        :description  => nattrs[9]
      }
    end
    self.attributes = new_attrs
    self
  end
  def invalid?
    return 'Description present on accepted transaction' if self.status == 'G' && !self.description.blank?
    return 'Description blank on declined transaction' if self.status == 'D' && self.description.blank?
    return 'SentDate is not a number' if self.sent_date =~ /\D/
    return 'SettleDate is not a number' if self.transacted_at =~ /\D/
    return false
  end

  def record_to_client!
    # self.client.transaction_id = self.transaction_id
    self.client.description = self.description
    self.client.status = self.status
    self.client.sent_date = self.sent_date
    self.client.transacted_at = self.transacted_at
    self.client.save
  end
end
