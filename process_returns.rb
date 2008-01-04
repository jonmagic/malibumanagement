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
# 2) Check for files from gotobilling & download them.
# 3) Read responses into mysql.
@batch = EftBatch.find(:first, :conditions => ['locked=1'], :order => 'for_month DESC')
@path = "EFT/#{@batch.for_month}/"
FileUtils.mkpath(@path)

!ARGV.include?('--limited') && !ARGV.include?('--revert-helios') && step("Checking for files on SFTP") do
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

!ARGV.include?('--limited') && !ARGV.include?('--revert-helios') && step("Reading return files into MySQL") do
  files = Dir.open(@path).collect.reject {|a| a !~ /^zone._#{Time.now.strftime("%Y%m")}.*\.csv$/}.sort
  
  files.each do |file|
    step("Reading #{file} into MySQL") do
      # clients = {}
      # invalids = []
      # header = nil
      # CSV::Reader.parse(File.open(@path+file, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |row|
      #   res = GotoResponse.new(row)
      #   unless header
      #     header = row
      #     next
      #   end
      #   if header.join(',') == 'MerchantID,FirstName,LastName,CustomerID,Amount,SentDate,SettleDate,TransactionID,TransactionType,Status,Description'
      #     invalid = res.invalid?
      #     # if !clients.has_key?(res.client_id) #Don't need to check for duplicates here, it's handled simply by checking if the status has changed since a previous recording.
      #     if res.client
      #       # Duplicate: First should always be an accept.. so delete the accept transaction
      #       #     and clear it from the goto_transaction so that the new response can be run.
      #       report "Copying client #{res.inspect} to MySQL..." if rand(20) == 15
      #       res.record_to_client!
      #     else
      #       # invalid: client doesn't exist
      #       invalid = "Client doesn't exist"
      #     end
      #     clients[res.client_id] = res
      #     invalids << "Client ##{res.client_id}: #{invalid}" if invalid
      #   else
      #     invalids = ["!!! INVALID RETURN FILE !!!"]
      #   end
      # end
      # report "Problems:\n\t#{invalids.join("\n\t")}"
    end
  end
end

!ARGV.include?('--revert-helios') && step("Recording all completed transactions to Helios") do
  # Find only those that have a status or are invalid
  trans = GotoTransaction.find(:all, :conditions => ['batch_id=? AND ((goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) OR (status IS NOT NULL AND status != ?))', @batch.id, '%'+[].to_yaml+'%', ''], :order => 'id ASC')
  report "There are #{trans.length} completed transactions to record to Helios."
  # Filter to those that don't have a transaction_id
  # to_record = trans.reject {|t| !t.transaction_id.blank? && t.transaction_id != 0}
  # FOR TESTING PURPOSES! (also tested on 20000002)
  # to_record = to_record[0..19]
  # * * * *
  # report "Of these, #{trans.length} have yet to be recorded to Helios."

# Commented just for safety in testing..
  # counts = {:accepted => 0, :declined => 0, :invalid => 0}
  # trans.each do |tran|
  #   step("Client ##{tran.client_id}") do
  #     counts[!tran.goto_invalid.to_a.blank? ? :invalid : (tran.status == 'G' ? :accepted : :declined)] += 1
  #     # The payment could be accepted, declined, or invalid.
  #     tran.record_to_helios!
  #   end
  # end
  # report "#{counts[:accepted]} Accepted, #{counts[:declined]} Declined, #{counts[:invalid]} Invalid"
end

ARGV.include?('--revert-helios') && step("Reverting everything recorded to Helios") do
  # Find only those that have a status or are invalid
  trans = GotoTransaction.find(:all, :conditions => ['batch_id=? AND ((goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) OR (status IS NOT NULL AND status != ?))', @batch.id, '%'+[].to_yaml+'%', ''], :order => 'id ASC')
  report "There are #{trans.length} completed transactions to revert in Helios."
  # Filter to those that don't have a transaction_id
  # to_record = trans.reject {|t| !t.transaction_id.blank? && t.transaction_id != 0}
  # FOR TESTING PURPOSES! (also tested on 20000002)
  # to_record = to_record[0..19]
  # * * * *
  # report "Of these, #{trans.length} have yet to be recorded to Helios."
  counts = {:accepted => 0, :declined => 0, :invalid => 0}
  trans.each do |tran|
    step("Client ##{tran.client_id}") do
      if tran.goto_invalid.to_a.blank? # Don't revert invalids until the revert_helios_client_profile! method is written and tested!
        counts[!tran.goto_invalid.to_a.blank? ? :invalid : (tran.status == 'G' ? :accepted : :declined)] += 1
        # The payment could be accepted, declined, or invalid.
        to_be_reverted = []
        to_be_reverted << 'Transaction' if !tran.transaction_id.blank? && tran.transaction_id != 0
        to_be_reverted << 'Note' if !tran.note_id.blank? && tran.note_id != 0
        to_be_reverted << 'Client Profile' if !tran.previous_balance.blank? || !tran.previous_payment_amount.blank?
        report "To be reverted: #{to_be_reverted.join(', ')}" if to_be_reverted.length > 1
        # tran.revert_helios_transaction!
        # tran.revert_helios!
      end
    end
  end
  report "#{counts[:accepted]} Accepted, #{counts[:declined]} Declined, #{counts[:invalid]} Invalid"
end
