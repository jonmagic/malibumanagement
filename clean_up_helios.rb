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
  CSV::Reader.parse(File.open('EFT/' + @for_month + '/payment.csv', 'rb')) do |row|
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
    step "Scrubbing Transactions for #{goto.client_id}" do
      transactions = find_vip_transactions_for_client(goto.client_id)
      transaction = transactions.pop
      transactions.each do |t|
        step "Deleting extraneous transaction #{t.id}" do
          t.update_on_master(:Deleted => true) # update_on_master takes care of the rest
        end
      end
      a = goto.amount.to_s.split(/\./).join('')
      amnt = a.chop.chop+'.'+a[-2,2]
      trans_attrs = {
        :id => goto.transaction_id.to_i > 0 ? goto.transaction_id.to_i : nil,
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
        :Location => goto.location,
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
          Helios::Transact.update_on_master(trans_attrs)
        end
      end
      #   +) Record transaction number to csv (log it)
      @logger.log(goto)
    end

    step "Scrubbing Notes for #{goto.client_id}" do
      notes = find_vip_notes_for_client(goto.client_id)
      note = notes.pop
      notes.each do |n|
        step "Deleting extraneous note #{n.id}" do
          n.update_on_master(:Deleted => true) # update_on_master takes care of the rest
        end
      end
      note.update_on_master(:Comments => goto.invalid? ? "#{'Invalid EFT: ' unless goto.bank_routing_number.to_s == '123'}#{goto.errors.full_messages.to_sentence}" : "EFT Declined: #{goto.response.description}")
    end

    step "Gathering and reporting Balances for #{goto.client_id}" do
      cp = Helios::ClientProfile.find(goto.client_id)
      @balances.log([cp.id, cp.Balance])
    end
  end
end

step "Recording transaction numbers in payment.csv" do
  CSV.open('EFT/' + @for_month + '/payment.csv', 'w') do |writer|
    writer << GotoTransaction.headers
    @payments.each {|goto| writer << goto.to_a }
  end
end

