module Goto
  class Response
    attr_accessor :merchant_id, :first_name, :last_name, :status, :client_id, :order_number, :term_code, :amount, :sent_date, :tran_date, :tran_time, :invoice_id, :auth_code, :description
    def attributes=(new_attributes)
      return if new_attributes.nil?
      with(new_attributes.dup) do |a|
        a.stringify_keys!
        a.each {|k,v| send(k + "=", a.delete(k)) if self.respond_to?("#{k}=")}
      end
    end

    def initialize(attrs) # From csv row, or from xml-hash
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

    def [](attr_name)
      self.send(attr_name.to_s)
    end

    def self.headers
      ['MerchantID', 'FirstName', 'LastName', 'CustomerID', 'Amount', 'SentDate', 'SettleDate', 'TransactionID', 'Status', 'Description']
    end

    # :merchant_id, :first_name, :status, :client_id, :order_number, :term_code, :tran_amount, :tran_date, :tran_time, :invoice_id, :auth_code, :description
    # MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,Status,Description
    def to_a
      [
        merchant_id,
        first_name,
        last_name,
        client_id,
        amount,
        sent_date || Time.now.strftime('%Y%m%d'),
        tran_date || Time.now.strftime('%Y%m%d'),
        order_number,
        status,
        description
      ]
    end

#     [1009104, "006", 158796, "Daniel", "Parker", "072402694", "5500024889", "Daniel Parker", nil, nil, "18.88", "ACH", "C", "Written", nil, false, "158796-20071031-124001", nil, "20071031", "164017", "R", nil, "0", nil]
  end
end
