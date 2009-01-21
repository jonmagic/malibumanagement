require 'rubygems'

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
# 2) Check for files from gotobilling & download them.
# 3) Read responses into mysql.
@batch = EftBatch.find(:first, :conditions => ['locked=1'], :order => 'for_month DESC')
@path = "EFT/#{@batch.for_month}/"
require 'fileutils'
FileUtils.mkpath(@path)

require 'net/ssh'
require 'net/sftp'
step("Downloading GotoBilling files for #{@batch.for_month}.") do
  files = []
  step("Connecting SFTP Session") do
    Net::SFTP.start(ZONE[:SFTP][:host], ZONE[:SFTP][:username], ZONE[:SFTP][:password]) do |sftp|
      handle = sftp.opendir(ZONE[:SFTP][:path])
      items = sftp.readdir(handle)
      files = items.collect {|i| i.filename}.reject {|a| a !~ Regexp.new("^zone._#{Time.now.strftime("%Y%m")}.*\.csv$")}
      sftp.close_handle(handle)
      files.each do |file|
        step("Downloading file #{file}") do
          sftp.get_file(ZONE[:SFTP][:path] + file, @path + file) && sftp.remove(ZONE[:SFTP][:path] + file)
        end
      end
    end
  end
  files.length
end unless ARGV.include?('--no-download')

require 'csv'
require 'goto_response'
step("Reading return files into MySQL") do
  files = Dir.open(@path).collect.reject {|a| a !~ /^zone._#{Time.now.strftime("%Y%m")}.*\.csv$/}.sort
  
  files.each do |file|
    step("Reading #{file} into MySQL") do
      clients = {}
      invalids = []
      header = nil
      CSV::Reader.parse(File.open(@path+file, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |row|
        res = GotoResponse.new(@batch.id, row)
        unless header
          header = row
          next
        end
        if header.join(',') == 'MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,TransactionType,Status,Description'
          invalid = res.invalid?
          # if !clients.has_key?(res.client_id) #Don't need to check for duplicates here, it's handled simply by checking if the status has changed since a previous recording.
          if res.transaction
            # Duplicate: First should always be an accept.. so delete the accept transaction
            #     and clear it from the goto_transaction so that the new response can be run.
            # report "Copying client #{res.inspect} to MySQL..." if rand(50) == 15
            res.record_to_transaction!
          else
            # invalid: client doesn't exist
            invalid = "Client doesn't exist"
          end
          clients[res.client_id] = res
          invalids << "Client ##{res.client_id}: #{invalid}" if invalid
        else
          invalids = ["!!! INVALID RETURN FILE !!!"]
        end
      end
      report "Problems:\n\t#{invalids.join("\n\t")}"
    end
  end
  ''
end unless ARGV.include?('--only-download')
