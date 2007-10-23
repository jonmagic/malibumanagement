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
  # Sends the generated payment CSV to the payment gateway
  path = 'EFT/'+batch.for_month+'/'
  retry_records = {}

  puts "Submitting #{batch.for_month}..."
  headers = true
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
      t.log_csv
    end
  end

  puts "Charging invalid accounts..."
  headers = true
  CSV::Reader.parse(File.open(path+'invalid.csv', 'rb')) do |row|
    if headers
      headers = false
      next
    end
    t = GotoTransaction.new_from_csv_row(row)
    # Post the amount to the client's account
    
  end
  retry_records.each_value do |t| # Retry once
    t.submit
    if t.received?
      t.log_csv
      retry_records.delete(id)
    end
  end
  retry_records.each_value do |t| #Retry again
    t.submit
    t.errors.add_to_base('Caused a timeout 3 times') if t.should_retry?
    t.log_csv
  end
  GotoTransaction.write_csv!(path+'returns_'+Time.now.strftime("%Y-%m-%d_%H")+'.csv')
  batch.update_attributes(:submitted_at => Time.now, :eft_ready => false)
  puts "Done submitting #{batch.for_month}!"
end

def sftp_submit(batch)
end
