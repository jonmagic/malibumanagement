module GotoCsv
  class Base
    attr_accessor :payments_csv

    def initialize(eft_path)
      @eft_path = eft_path
      self.payments_csv = eft_path + 'returns_immediate.csv'
      true
    end

#ok, for declined accounts we need to set client_profile.payment_amount = client_profile.payment_amount + 18.88 + 5
#and set client_profile.balance = client_profile.balance + 18.88 + 5
#thats for zone2 of course
#zone1 will have to be 19.99
#oh, and set client_profile.Date_Due = today
#it was Payment_Amount not payment_amount
#and Balance  not balance

    def record(goto) # Receives credit-card payments after they've been processed, invalids without being processed, and ach payments after they've been processed. All come in the form of a GotoTransaction, with response values either injected or returned from GotoBilling.
      amnt = (goto.amount.to_f/100).to_s
      trans_attrs = {
        :Descriptions => case # Needs to include certain information for different cases
          when goto.invalid?
            "VIP: Invalid EFT: ##{goto.errors.full_messages.to_sentence}"
          when goto.declined?
            "VIP: Declined: ##{goto.response['term_code']}"
          else
            "VIP: Accepted ##{goto.response['auth_code']}"
          end,
        :client_no => goto.account_id,
        :Last_Name => goto.last_name,
        :First_Name => goto.first_name,
        :CType => 'S',
        :Code => 'EFT Active',
        :Division => ZONE[:Division], # 2 for zone1
        :Department => ZONE[:Department], # 7 for zone1
        :Location => goto.location,
        :Price => amnt,
        :Check => goto.paid_now? && goto.ach? ? amnt : 0,
        :Charge => goto.paid_now? && goto.credit_card? ? amnt : 0,
        :Credit => !goto.paid_now? ? amnt : 0,
        :Wait_For => case
          when goto.paid_now? && goto.ach?
            'K'
          when goto.paid_now? && goto.credit_card?
            'N'
          else
            'I'
          end
      }
      if trans_attrs[:id]
        Helios::Transact.update_on_master(trans_attrs)
      else
        goto.transaction_id = Helios::Transact.create_on_master(trans_attrs)
      end
      Helios::Note.create_on_master(
        :Client_no => goto.account_id,
        :Location => goto.location,
        :Last_Name => goto.last_name,
        :First_Name => goto.first_name,
        :Comments => goto.invalid? ? "Invalid EFT: #{goto.errors.full_messages.to_sentence}" : "EFT Declined: #{goto.response['description']}",
        :EmpCode => 'EC',
        :Interrupt => true,
        :Deleted => false
      ) if (goto.invalid? || goto.declined?) && !goto.recorded?
      goto.recorded = true if goto.paid_now? || goto.declined?
      
      file = File.open(self.payments_csv, 'a')
        raise "Could not open returns file for record-keeping!!" if file.nil?
        file.write(goto.to_return.map {|x| x = "\"#{x}\"" if x =~ /,/}.join(','))
        file.close
    end

    # def to_file!
    #   backup = "payment_backup-#{Time.now.strftime("%j-%H%M")}.csv"
    #   File.copy(@eft_path + 'payment.csv', @eft_path + backup)
    #   CSV.open(@eft_path + 'payment.csv', 'w') do |csv|
    #     csv << ['AccountId', 'Location', 'MerchantId', 'FirstName', 'LastName', 'BankRoutingNumber', 'BankAccountNumber', 'NameOnCard', 'CreditCardNumber', 'Expiration', 'Amount', 'Type', 'AccountType', 'Authorization']
    #     self.payments_csv.each {|row| csv << row}
    #   end
    #   true
    # end
  end

  
  # def self.log_this(obj)
  #   return false unless obj.submitted?
  #   response = obj.instance_variable_get('@response')
  #   @csv ||= []
  #   if !obj.errors.blank?
  #     response['status'] = 'X'
  #     response['description'] = obj.errors.full_messages.to_sentence
  #   end
  #   # Pull values from the response, or from the GotoTransaction if not in the response
  #   # account id, transaction type, merchant id, amount, transaction date, invoice id, status, status description
  #   @csv << [
  #     response['account_id']        || obj.account_id,
  #     response['type']              || obj.type,
  #     response['merchant_id']       || obj.merchant_id,
  #     response['amount']            || obj.amount,
  #     response['transaction_date']  || Time.now,
  #     response['invoice_id']        || obj.invoice_id,
  #     response['status'],
  #     response['description']
  #   ]
  # end
  # def log_this
  #   self.class.log_this(self)
  # end

  

  def self.included?(base)
    Helios::Note.extend(NotesExt)
  end
  module NotesExt
    def self.create_on_master(attrs)
      self.master[self.master.keys[0]].create(attrs.merge(:Last_Mdt => Time.now - 4.hours, :Location => LOCATIONS.reject {|k,v| v[:name] != self.master.keys[0]}.keys[0] ))
      Helios::ClientProfile.touch_on_master(attrs[:Client_no])
    end
  end
end
