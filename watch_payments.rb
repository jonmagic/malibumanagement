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
    rows_submitted = 0
    CSV::Reader.parse(File.open(batch.eft_path+'payment.csv', 'rb')) do |row|
      if headers
        headers = false
        next
      elsif row.nil?
        next
      end
      rows_submitted += 1
      goto = GotoTransaction.new_from_csv_row(row)
      unless goto.submitted?
        step "Submitting ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}" do
          retry_records[goto.client_id] = goto # First add to retry, remove when successful
          goto.submit # (Validates before submitting)
          ActionController::Base.logger.info({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
          puts({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
          unless goto.should_retry?
            retry_records.delete(goto.client_id)
            @returns.record(goto)
          end
        end
      end
    end
    retry_records.each do |k,goto| # Retry once
      step "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}" do
        goto.submit
        msg = {'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']]
          ActionController::Base.logger.info(msg)
          puts msg
        if goto.received?
          @returns.record(goto)
          retry_records.delete(k)
        end
      end
    end
    retry_records.each_value do |goto| #Retry again
      step "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}" do
          ActionController::Base.logger.info(msg)
          puts msg
        goto.submit
        msg = {'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']]
          ActionController::Base.logger.info(msg)
          puts msg
        @returns.record(goto)
      end
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
    if Dir.open('EFT/'+batch.for_month).collect.reject {|a| a !~ /returns_.*\.csv$/}.empty?
      API == 'http' ? http_submit(batch) : sftp_submit(batch)
    end
  end
end while sleep(120) # Wait one minute between checks.
