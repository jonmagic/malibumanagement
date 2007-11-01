require 'csv'
module GotoCsv
  class Extras
    class << self
      def push_to_helios(goto)
        a = goto.amount.to_f.to_s.split(/\./).join('')
        amnt = a.chop.chop+'.'+a[-2,2]
        trans_attrs = {
          :Descriptions => case # Needs to include certain information for different cases
            when goto.invalid?
              "VIP: Invalid EFT: ##{goto.errors.full_messages.to_sentence}"
            when goto.declined?
              "VIP: Declined: ##{goto.response['term_code']}"
            else
              "VIP: Accepted ##{goto.response['auth_code']}"
            end,
          :client_no => goto.client_id,
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
          :Credit => goto.declined? || goto.invalid? ? amnt : 0,
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
        if (goto.declined? || goto.invalid?) && !goto.recorded?
          cp = Helios::ClientProfile.find(goto.account_id.to_i)
          n = Time.now.gmtime
          cp.update_attributes(
            :Payment_Amount => cp.Payment_Amount.to_f + goto.amount + (goto.submitted? ? 5 : 0),
            :Balance => cp.Balance.to_f + goto.amount + (goto.submitted? ? 5 : 0),
            :Date_Due = n,
            :Last_Mdt = Time.gm(n.year, n.month, n.mday, n.hour+1, 0, 0)
          ) if Time.now > Time.parse('2007/11/01 07:00:00')

          # Helios::ClientProfile.update_on_master(
          #   :id => cp.id,
          #   :Payment_Amount => cp.Payment_Amount.to_f + goto.amount + (goto.submitted? ? 5 : 0),
          #   :Balance => cp.Balance.to_f + goto.amount + (goto.submitted? ? 5 : 0),
          #   :Date_Due = n,
          #   :Last_Mdt = Time.gm(n.year, n.month, n.mday, n.hour+1, 0, 0)
          # )
          Helios::Note.create_on_master(
            :Client_no => goto.client_id,
            :Location => goto.location,
            :Last_Name => goto.last_name,
            :First_Name => goto.first_name,
            :Comments => goto.invalid? ? "Invalid EFT: #{goto.errors.full_messages.to_sentence}" : "EFT Declined: #{goto.response['description']}",
            :EmpCode => 'EC',
            :Interrupt => true,
            :Deleted => false
          )
        end
        goto.recorded = true if goto.paid_now? || goto.declined? || goto.invalid?
        return goto
      end
    end
  end

  class Base
    attr_accessor :payments_csv

    def initialize(eft_path)
      @eft_path = eft_path
      self.payments_csv = eft_path + 'returns_immed_'+ Time.now.to_f.to_s.split(/\./).join('')[-10,10] +'.csv'
      file = File.open(self.payments_csv, 'w')
        raise "Could not open returns file for record-keeping!!" if file.nil?
        file.write(Goto::Response.headers.map {|x| x = "\"#{x}\"" if x =~ /,/; x}.join(',') + "\n")
        file.close
      true
    end

    def record(goto) # Receives credit-card payments after they've been processed, invalids without being processed, and ach payments after they've been processed. All come in the form of a GotoTransaction, with response values either injected or returned from GotoBilling.
      file = File.open(self.payments_csv, 'a')
        raise "Could not open returns file for record-keeping!!" if file.nil?
        file.write(goto.response.to_a.map {|x| x = "\"#{x}\"" if x =~ /,/; x}.join(',') + "\n")
        file.close
    end
  end

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
