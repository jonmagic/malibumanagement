require 'ftools'
require 'goto_csv'
API = 'http'

def step(description)
  puts(description+'...')
  ActionController::Base.logger.info(description+'...')
  begin
    yield if block_given?
    puts(description+" -> Done.")
    ActionController::Base.logger.info(description+" -> Done.")
  rescue => e
    puts("["+description+"] Caused Errors: {#{e}}")
    ActionController::Base.logger.info("["+description+"] Caused Errors: {#{e}}")
  end
end

def http_submit(batch) # Sends the generated payment CSV to the payment gateway
  @returns = GotoCsv::Base.new(batch.eft_path)
  retry_records = {}

  step "Charging invalid accounts" do
    headers = true
    CSV::Reader.parse(File.open(batch.eft_path+'invalid_efts.csv', 'rb')) do |row|
      if headers
        headers = false
        next
      end
      t = GotoTransaction.new(Helios::Eft.find(row[0]))
      GotoCsv::Extras.push_to_helios(t)
    end
  end
  step "Submitting #{batch.for_month}" do
    headers = true
    CSV::Reader.parse(File.open(batch.eft_path+'payment.csv', 'rb')) do |row|
      if headers
        headers = false
        next
      end
      goto = GotoTransaction.new_from_csv_row(row)
      unless goto.submitted?
ActionController::Base.logger.info("Submitting ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}")
puts "Submitting ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}"
        goto.submit # (Validates before submitting)
ActionController::Base.logger.info({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
puts({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
        if goto.should_retry?
          retry_records[goto.client_id] = goto
        else
          @returns.record(goto)
        end
      end
    end
    retry_records.each do |k,goto| # Retry once
      msg = "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}"
        ActionController::Base.logger.info(msg)
        puts msg
      goto.submit
      msg = {'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']]
        ActionController::Base.logger.info(msg)
        puts msg
      if goto.received?
        @returns.record(goto)
        retry_records.delete(k)
      end
    end
    retry_records.each_value do |goto| #Retry again
      msg = "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}"
        ActionController::Base.logger.info(msg)
        puts msg
      goto.submit
      msg = {'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']]
        ActionController::Base.logger.info(msg)
        puts msg
      @returns.record(goto)
    end
  end
  step "Finishing up #{batch.for_month}" do
    batch.submitted_at = Time.now
    batch.eft_ready = false
    batch.save!
  end
end

def sftp_submit(batch)
end

begin
  EftBatch.find_all_by_eft_ready(true).each do |batch|
    API == 'http' ? http_submit(batch) : sftp_submit(batch)
  end
end while sleep(120) # Wait one minute between checks.
