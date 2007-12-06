require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'fileutils'
require 'csv'
require 'goto_response'

def report(txt)
  begin
    puts(("  "*CoresExtensions::StepLevel[0]) + ">" + txt)
    ActionController::Base.logger.info("  "*CoresExtensions::StepLevel[0] + ">" + txt)
  rescue => e
    puts e
  end
end

# Process:
# 1) Shuffle through Invalids and create transactions & notes for them.
# 2) Once and then every hour, check for files from gotobilling & download them, then read them into mysql.
@batch = EftBatch.find(:first, :conditions => ['locked=1'], :order => 'for_month DESC')
@path = "EFT/#{@batch.for_month}/"
FileUtils.mkpath(@path)

step("Checking for files on SFTP") do
  files = []
  step("Connecting SFTP Session") do
    Net::SFTP.start(ZONE[:SFTP][:host], ZONE[:SFTP][:username], ZONE[:SFTP][:password]) do |sftp|
      handle = sftp.opendir(ZONE[:SFTP][:path])
      items = sftp.readdir(handle)
      files = items.collect {|i| i.filename}.reject {|a| a !~ Regexp.new("^zone._#{Time.now.strftime("%Y%m")}.*\.csv$")}
      sftp.close_handle(handle)
      files.each do |file|
        step("Downloading file #{file}") do
          sftp.get_file(ZONE[:SFTP][:path] + file, @path + file) # && sftp.remove(ZONE[:SFTP][:path] + file)
        end
      end
    end
  end
  files.length
end

step("Reading return files into MySQL") do
  files = Dir.open(@path).collect.reject {|a| a !~ /^zone._#{Time.now.strftime("%Y%m")}.*\.csv$/}.sort
  
  files.each do |file|
    step("Reading #{file} into MySQL") do
      clients = {}
      CSV::Reader.parse(File.open(@path+file, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |row|
        # Invalid lines, write to a new file, 'zone1_20071204_invalid_rows.csv'
        res = GotoResponse.new(row)
        next if res.merchant_id == 'MerchantID'
        invalid = res.invalid?
        if !clients.has_key?(res.client_id)
          if res.client
            res.record_to_client!
          else
            # invalid: client doesn't exist
            invalid = "Client doesn't exist"
          end
        else
          # invalid: duplicate row
          invalid = "Duplicate GotoBilling response"
        end
        clients[res.client_id] = res
        puts "Client ##{res.client_id}: #{invalid}" if invalid
      end
    end
  end
end

step("Recording all completed transactions to Helios") do
  # Find only those that have a status or are invalid
  trans = GotoTransaction.find(:all, :conditions => ['batch_id=? AND ((goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) OR (status IS NOT NULL AND status != ?))', @batch.id, '%'+[].to_yaml+'%', ''], :order => 'id ASC')
  report "There are #{trans.length} completed transactions."
  # Filter to those that don't have a transaction_id
  # to_record = trans.reject {|t| !t.transaction_id.blank?}
  # FOR TESTING PURPOSES! (also tested on 20000002)
  # to_record = to_record[0..19]
  # * * * *
  # report "Of these, #{trans.length} have yet to be recorded to Helios."
  counts = {:accepted => 0, :declined => 0, :invalid => 0}
  trans.each do |tran|
    step("Client ##{tran.client_id}") do
      counts[!tran.goto_invalid.to_a.blank? ? :invalid : (tran.status == 'G' ? :accepted : :declined)] += 1
      # The payment could be accepted, declined, or invalid.
      tran.record_to_helios!
    end
  end
  report "#{counts[:accepted]} Accepted, #{counts[:declined]} Declined, #{counts[:invalid]} Invalid"
end

