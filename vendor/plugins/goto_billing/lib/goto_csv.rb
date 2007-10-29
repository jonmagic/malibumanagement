module GotoCsv
  class Base
    attr_accessor :payments_csv

    def initialize(eft_path)
      @eft_path = eft_path
    end

    def record(goto) # Receives credit-card payments after they've been processed, invalids without being processed, and ach payments after they've been processed. All come in the form of a GotoTransaction, with response values either injected or returned from GotoBilling.
      self.payments_csv ||= []
      trans_attrs = {
        :Descriptions => case # Needs to include certain information for different cases
          when goto.invalid?, "VIP: Invalid EFT: ##{goto.errors.full_messages.to_sentence}"
          when goto.declined?, "VIP: Declined: ##{goto.response['term_code']}"
          else "VIP: Accepted ##{goto.response['auth_code']}"
        end,
        :client_no => goto.account_id,
        :Last_Name => goto.last_name,
        :First_Name => goto.first_name,
        :CType => 'S',
        :Code => 'EFT Active',
        :Division => ZONE[:Division], # 2 for zone1
        :Department => ZONE[:Department], # 7 for zone1
        :Location => goto.location,
        :Price => goto.amount,
        :Check => goto.paid_now? && goto.ach? ? goto.amount : 0,
        :Charge => goto.paid_now? && goto.credit_card? ? goto.amount : 0,
        :Credit => !goto.accepted? ? goto.amount : 0
      }
      trans_attrs[:id] ? Helios::Transact.update_on_master(trans_attrs) : Helios::Transact.create_on_master(trans_attrs)
      Helios::Note.create_on_master(
        :Client_no => goto.account_id,
        :Last_Name => goto.last_name,
        :First_Name => goto.first_name,
        :Comments => goto.invalid? ? "Invalid EFT: #{goto.errors.full_messages.to_sentence}" : "Declined: #{goto.response['description']}",
        :EmpCode => 'EC',
        :Interrupt => true,
        :Deleted => false
      ) if (goto.invalid? || goto.declined?) && !goto.recorded?
      goto.recorded = true if goto.paid_now? || goto.declined?
      self.payments_csv << goto.to_a
    end

    def to_file!(filename)
      backup = "payments_backup-#{Time.now.strftime("%j-%H%M")}.csv"
      File.copy(@eft_path + 'payments.csv', @eft_path + backup)
      CSV.open(filename, 'w') do |csv|
        self.payments_csv.each {|row| csv << row}
      end
      true
    end
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
