#!/usr/bin/env /Users/daniel/Sites/sixsigma/branches/malibu/script/runner

require 'ftools'
require 'goto_csv'
API = 'http'

def http_submit(batch) # Sends the generated payment CSV to the payment gateway
  @returns = GotoCsv::Base.new(batch.eft_path)
  begin # Charging invalid accounts
    retry_records = {}
ActionController::Base.logger.info("Charging invalid accounts...")
puts "Charging invalid accounts..."
    headers = true
    CSV::Reader.parse(File.open(batch.eft_path+'invalid_efts.csv', 'rb')) do |row|
      if headers
        headers = false
        next
      end
      t = GotoTransaction.new(Helios::Eft.find(row[0]))
      @returns.record(t)
    end
  end
  begin # Submitting payments to gotobilling
ActionController::Base.logger.info("Submitting #{batch.for_month}...")
puts "Submitting #{batch.for_month}..."
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
ActionController::Base.logger.info("Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}")
puts "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}"
      goto.submit
ActionController::Base.logger.info({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
puts({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
      if goto.received?
        @returns.record(goto)
        retry_records.delete(k)
      end
    end
    retry_records.each_value do |goto| #Retry again
ActionController::Base.logger.info("Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}")
puts "Retrying ##{goto.client_id}, #{goto.account_type == 'C' ? 'Bank: Checking' : (goto.account_type == 'S' ? 'Bank: Savings' : 'Credit Card')}, $#{goto.amount}"
      goto.submit
ActionController::Base.logger.info({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
puts({'G' => 'Paid Instantly', 'A' => 'Accepted', 'T' => 'Timeout: Retrying Later', 'D' => 'Declined!', 'C' => 'Cancelled (?)', 'R' => 'Received for later processing'}[goto.response['status']])
      @returns.record(goto)
    end
  end
  begin # Finishing up
    # @returns.to_file! #(batch.eft_path+'returns_'+Time.now.strftime("%Y-%m-%d_%H")+'.csv')
    # batch.update_attributes(:submitted_at => Time.now, :eft_ready => false)
ActionController::Base.logger.info("Done submitting #{batch.for_month}!")
puts "Done submitting #{batch.for_month}!"
  end
end

def sftp_submit(batch)
end

begin
  EftBatch.find_all_by_eft_ready(true).each do |batch|
    unless batch.submitted_at
      API == 'http' ? http_submit(batch) : sftp_submit(batch)
    end
  end
end while sleep(60) # Wait one minute between checks.
