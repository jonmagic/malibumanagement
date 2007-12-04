require 'ftools'
require 'csv'

# 1) Look for transaction
#   +) If transaction exists
#     -) are there more than one?
#       .) yes - delete older ones
#     -) EDIT transaction
#   +) If transaction doesn't exist
#     -) CREATE transaction
#   +) Record transaction number to csv (log it)
# 2) Look for Notes
#   +) If exist and shouldn't, remove
#   +) If don't exist and should, create
# 3) Notice the balance and payment amount, report balance.

def step(description)
  logit = lambda {|txt|
    begin
      puts txt
      ActionController::Base.logger.info(txt)
    rescue
    end
  }
  logit.call(description+'...')
  begin
    v = yield if block_given?
    logit.call(description+" -> Done.")
    return v
  rescue => e
    logit.call("["+description+"] Caused Errors: {#{e}}")
    return false
  end
end

class CsvLogger
  def initialize(path, prefix, headers)
    @path = path
    @prefix = prefix
    @headers = headers
    @csv = "filename_that_can't_exist_$%^&*##!@$...!!!"
  end

  def log(arrayable) # Receives credit-card payments after they've been processed, invalids without being processed, and ach payments after they've been processed. All come in the form of a GotoTransaction, with response values either injected or returned from GotoBilling.
    gen_csv() unless File.exists?(@csv)
    file = File.open(@csv, 'a')
      raise "Could not open returns file for record-keeping!!" if file.nil?
      file.write(arrayable.to_a.map {|x| x = "\"#{x}\"" if x =~ /,/; x}.join(',') + "\n")
    file.close
  end
  
  private
    def gen_csv
      @csv = @path + @prefix + '_' + Time.now.to_f.to_s.split(/\./).join('')[-10,10] +'.csv'
      file = File.open(@csv, 'w')
        raise "Could not open returns file for record-keeping!!" if file.nil?
        file.write(@headers.map {|x| x = "\"#{x}\"" if x =~ /,/; x}.join(',') + "\n")
      file.close
      return @csv
    end
end

def clients_from_payment_csv
  payments = []
  headers = true
  CSV::Reader.parse(File.open('EFT/' + @for_month + '/payment_returned.csv', 'rb')) do |row|
    if headers
      headers = false
      next
    end
    goto = GotoTransaction.new_from_csv_row(row)
    payments << goto
  end
  return payments
end

def find_vip_transactions_for_client(id)
  Helios::Transact.find(:all, :conditions => ["[client_no]=? AND [Last_Mdt] > ? AND [Code] LIKE ?", id, Time.parse('2007/11/01'), '%EFT%'], :order => '[Last_Mdt]')
end
def find_vip_notes_for_client(id)
  Helios::Note.find(:all, :conditions => ["[Client_no]=? AND [Last_Mdt] > ? AND [Comments] LIKE ?", id, Time.parse('2007/11/01'), '%EFT%'])
end



@for_month = Time.now.strftime("%Y") + '/' + (Time.now.strftime("%m").to_i).to_s
@logger = CsvLogger.new('EFT/' + @for_month + '/', 'transactions', GotoTransaction.headers)
@balances = CsvLogger.new('EFT/' + @for_month + '/', 'balances', ['ClientId', 'Balance'])
@payments = clients_from_payment_csv()
step "Scrubbing accounts" do
  @payments.each do |goto|
    puts "\n"
    step "Scrubbing Transactions for #{goto.client_id}" do
      transactions = find_vip_transactions_for_client(goto.client_id)
      transaction = transactions.pop
      transactions.each do |t|
        step "Deleting extraneous transaction #{t.id}" do
          t.delete_from_master # update_on_master takes care of the rest
        end
      end
      a = goto.amount.to_s.split(/\./).join('')
      amnt = a.chop.chop+'.'+a[-2,2]
      trans_attrs = {
        :Descriptions => case # Needs to include certain information for different cases
          when goto.invalid?
            "#{'VIP: Invalid EFT: ' unless goto.bank_routing_number.to_s == '123'}#{goto.errors.full_messages.to_sentence}"
          when goto.declined?
            "VIP: Declined: ##{goto.response['term_code']}"
          else
            "VIP: Accepted: ##{goto.response['auth_code']}"
          end,
        :client_no => goto.client_id,
        :Last_Name => goto.last_name,
        :First_Name => goto.first_name,
        :CType => 'S',
        :Code => 'EFT Active',
        :Division => ZONE[:Division], # 2 for zone1
        :Department => ZONE[:Department], # 7 for zone1
        :Location => '001',
        :Price => amnt,
        :Check => goto.paid_now? && goto.ach? ? amnt : 0,
        :Charge => goto.paid_now? && goto.credit_card? ? amnt : 0,
        :Credit => goto.declined? || goto.invalid? ? amnt : 0,
        :Wait_For => case
          when goto.declined? || goto.invalid?
            'I'
          when goto.ach?
            'K'
          when goto.credit_card?
            'N'
          end
      }
      trans_attrs[:OTNum] = transaction.OTNum if !transaction.OTNum.nil?
      if transaction.nil?
        step "Creating Transaction for #{goto.client_id}" do
          goto.transaction_id = Helios::Transact.create_on_master(trans_attrs)
        end
      else
        step "Updating Transaction ##{transaction.id}" do
          goto.transaction_id = Helios::Transact.update_on_master(trans_attrs)
        end
      end
      #   +) Record transaction number to csv (log it)
      @logger.log(goto)
    end

    cp = Helios::ClientProfile.find(goto.client_id.to_i)
    step "Backing up Balance for #{goto.client_id}" do
      puts "BALANCE:     $#{cp.Balance.to_s}"
      @balances.log([cp.id, cp.Balance])
    end

    step "Recording Balance in ClientProfile" do
      a = goto.amount.to_s.split(/\./).join('')
      amnt = a.chop.chop+'.'+a[-2,2]
      n = Time.now - 5.hours
      cpARes = Helios::ClientProfile.master[Helios::ClientProfile.master.keys[0]]
      cpARes.primary_key = 'Client_no'
      rec = cpARes.new
      rec.Client_no = cp.id
      rec.Payment_Amount = cp.Payment_Amount.to_f + amnt.to_f + (goto.submitted? ? 5 : 0)
      rec.Balance = cp.Balance.to_f + amnt.to_f + (goto.submitted? ? 5 : 0)
      rec.Date_Due = Time.gm(n.year, n.month, 1, 0, 0, 0)
      rec.Last_Mdt = n
      rec.save
    end if goto.declined? || goto.invalid?

    step "Scrubbing Notes for #{goto.client_id}" do
      # notes = find_vip_notes_for_client(goto.client_id)
      # note = notes.pop
      # notes.each do |n|
      #   step "Deleting extraneous note #{n.id}" do
      #     n.update_on_master(:Deleted => true) # update_on_master takes care of the rest
      #   end
      # end
      should_be_note = (goto.declined? || goto.invalid?) ? true : false
      if should_be_note
        # if note.nil?
          step "Creating Note on master" do
            note = Helios::Note.create_on_master(
              :Client_no => goto.client_id,
              :Location => '001',
              :Last_Name => goto.last_name,
              :First_Name => goto.first_name,
              :Comments => goto.invalid? ? "#{'Invalid EFT: ' unless goto.bank_routing_number.to_s == '123'}#{goto.errors.full_messages.to_sentence}" : "EFT Declined: #{goto.response['description']}",
              :EmpCode => 'EC',
              :Interrupt => true,
              :Deleted => false
            )
          end
        # else
        #   step "Updating Note on master" do
        #     note.update_on_master(:Interrupt => true, :Deleted => false, :Comments => goto.invalid? ? "#{'Invalid EFT: ' unless goto.bank_routing_number.to_s == '123'}#{goto.errors.full_messages.to_sentence}" : "EFT Declined: #{goto.response.description}")
        #   end
        # end
      else
        # if !note.nil?
        #   step "Deleting note from master" do
        #     note.delete_from_master
        #   end
        # end
      end
    end
  end
end

