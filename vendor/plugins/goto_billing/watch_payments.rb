#!/usr/bin/env /Users/daniel/Sites/sixsigma/branches/malibu/script/runner

# The Process:
# Watch for any EftBatch record to have an attribute of :eft_ready == true, for each:
  # 1) Read the payments.csv
  # 2) For each line create a GotoTransaction, submit it
  # 3) Create a returns file for all that don't return status 'R', retry for any status 'T'

API = 'http'

while sleep(60) # Wait one minute between checks.
  EftBatch.find_all_by_eft_ready(true).each do |batch|
    API == 'http' ? http_submit(batch) : sftp_submit(batch)
  end
end

def http_submit(batch)
  puts "Submitting #{batch.for_month}..."
  # Sends the generated payment CSV to the payment gateway
  headers = true
  path = 'EFT/'+batch.for_month+'/'
  return_file = path+'returns_'+Time.now.strftime("%Y-%m-%d_%H")+'.csv'
  retry_records = {}
  CSV::Reader.parse(File.open(path+'payment.csv', 'rb')) do |row|
    if headers
      headers = false
      next
    end
    t = GotoTransaction.new_from_csv_row(row)
    t.submit # (Validates before submitting)
    if t.should_retry?
      retry_records[t.account_id] = t
    else
      t.record_response(return_file)
    end
  end
  retry_records.each_value do |t| # Retry once
    t.submit
    if t.received?
      t.record_response(return_file)
      retry_records.delete(id)
    end
  end
  retry_records.each_value do |t| #Retry again
    t.submit
    t.errors.add_to_base('Caused a timeout 3 times') if t.should_retry?
    t.record_response(return_file)
  end
  batch.update_attributes(:submitted_at => Time.now, :eft_ready => false)
  puts "Done submitting #{batch.for_month}!"
end

def sftp_submit(batch)
end
