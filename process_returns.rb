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

step("Recording Invalids to Helios") do
  invds = []
  step("Finding Invalids") do
    invds = GotoTransaction.find(:all, :conditions => ['batch_id=? AND (goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?))', @batch.id, '%'+[].to_yaml+'%'], :order => 'id ASC')
  # FOR TESTING PURPOSES!
    # invds = invds[0..4]
  # * * * *
    report "There are #{invds.length} invalid payment requests."
  end

  step("Processing Invalids one by one") do
    invds.each do |invd|
      if invd.transaction_id && invd.note_id && invd.previous_balance
        report "#{invd.id} is already up to date in Helios."
      else
        step("Processing #{invd.id}") do
          step("Recording transaction") do
            invd.record_transaction_to_helios!
            invd.transaction_id
          end unless invd.transaction_id
          step("Recording note") do
            invd.record_note_to_helios!
            invd.note_id
          end unless invd.note_id
          step("Recording client profile") do
            invd.record_client_profile_to_helios!
          end unless invd.previous_balance
        end
      end
    end
    true
  end
  true
end

step("Checking for files on SFTP") do
  files = []
  step("Connecting SFTP Session") do
    Net::SFTP.start(ZONE[:SFTP][:host], ZONE[:SFTP][:username], ZONE[:SFTP][:password]) do |sftp|
      handle = sftp.opendir(ZONE[:SFTP][:path])
      items = sftp.readdir(handle)
      files = items.collect {|i| i.filename}.reject {|a| a !~ /^zone._.*\.csv$/}
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
  files = Dir.open(@path).collect.reject {|a| a !~ /^zone._.*\.csv$/}.sort
  
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
