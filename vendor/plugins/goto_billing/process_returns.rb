#!/usr/bin/env /Users/daniel/Sites/sixsigma/branches/malibu/script/runner

# The Process:
# Check the sftp site every hour for files from gotobilling, download them and process them as responses to GotoTransactions.

require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'goto_csv'

host = 'sftp.malibutan.com' || 'sftp.malibu-tanning.com'
username = 'malibu2' || 'malibu'
password = 'gn1nn4t'
path = "/home/#{username}/gotobilling"
while sleep(1800) # Wait one hour between checks.
  files = []
  for_month = Time.now.strftime("%Y") + '/' + Time.now.strftime("%m")
  @batch = EftBatch.find_or_create_by_for_month(for_month)
  @returns = GotoCsv::Base.new(@batch.eft_path)
  Net::SFTP.start(host, username, password) do |sftp|
    handle = sftp.opendir(path)
    items = sftp.readdir(handle)
    files = items.collect {|i| i.filename}.reject {|a| a !~ /\.csv$/}
    sftp.close_handle(handle)
    files.each do |file|
      puts "Downloading file #{file}..."
      sftp.remove(path+'/'+file) if sftp.get_file(path+'/'+file, "EFT/"+for_month+'/'+file)
    end
  end

ActionController::Base.logger.info("Loading GotoBilling responses...")
  @responses = {}
  Dir.open('EFT/'+for_month).collect.reject {|a| a !~ /returns.*\.csv$/}.each do |file|
    headers = []
    CSV::Reader.parse(File.open("EFT/"+for_month+'/'+file, 'rb')) do |row|
      if headers.blank?
        headers = row.map {|r| r.underscore}
        next
      end
      response = {}
      headers.length.times do |i|
        response[headers[i]] = row[i]
      end
      goto = pending[response['invoice_id']]
      goto.instance_variable_set('@response', response)
      goto.instance_variable_set('@new_record', false)
      # Now 't' is just as if we just now submitted the transaction and got a response back into it.
      @responses[goto.account_id] = goto
    end
    File.rename(file, file+'.recorded')
  end

ActionController::Base.logger.info("Loading pending transactions...")
  pending = {}
  headers = true
  CSV::Reader.parse(File.open('EFT/'+for_month+'/payment.csv', 'rb')) do |row|
    if headers
      headers = false
      next
    end
    goto = GotoTransaction.new_from_csv_row(row)
    goto.attributes = {
      
    } if response = @responses[goto.account_id]
    @returns.record(goto)
  end
ActionController::Base.logger.info("Processing responses...")

ActionController::Base.logger.info("Saving results to batch...")
  @returns.to_file!(batch.eft_path+'returns_'+Time.now.strftime("%Y-%m-%d_%H")+'.csv')
  # batch.update_attributes(:submitted_at => Time.now, :eft_ready => false)
end
