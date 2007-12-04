require 'rubygems'
require 'net/ssh'
require 'net/sftp'

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


step("Recording Invalids to Helios") do
  invds = []
  step("Finding Invalids") do
    invds = GotoTransaction.find(:all, :conditions => ['batch_id=? AND (goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?))', @batch.id, '%'+[].to_yaml+'%'], :order => 'id ASC')
  # FOR TESTING PURPOSES!
    invds = invds[0..4]
  # * * * *
    report "There are #{invds.length} invalid payment requests."
    invds_not_recd = GotoTransaction.find(:all, :conditions => ['id < ? AND batch_id=? AND (goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) AND order_number IS NULL', invds.last.id+1, @batch.id, '%'+[].to_yaml+'%'], :order => 'id ASC')
    report "Of these, there are #{invds_not_recd.length} not yet recorded into Helios."
  end

  step("Processing Invalids one by one") do
    invds.each do |invd|
      step("Processing #{invd.id}") do
        invd.record_to_helios!
      end
    end
    true
  end
  true
end


step("Downloading files from SFTP") do
  files = []
  step("Connecting SFTP Session") do
    Net::SFTP.start(ZONE[:SFTP][:host], ZONE[:SFTP][:username], ZONE[:SFTP][:password]) do |sftp|
      handle = sftp.opendir(ZONE[:SFTP][:path])
      items = sftp.readdir(handle)
      files = items.collect {|i| i.filename}.reject {|a| a !~ /\.csv$/}
      sftp.close_handle(handle)
      files.each do |file|
        step("Downloading file #{file}") do
          sftp.remove(ZONE[:SFTP][:path] + '/' + file) if sftp.get_file(ZONE[:SFTP][:path] + '/' + file, "EFT/" + @for_month + '/' + file)
        end
      end
    end
  end
  files.length
end if false
