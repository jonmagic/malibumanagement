require 'rubygems'
require 'net/ssh'
require 'net/sftp'

def report(txt)
  begin
    puts(("  "*CoresExtensions::StepLevel[0]) + " > " + txt)
    ActionController::Base.logger.info("  "*CoresExtensions::StepLevel[0] + " > " + txt)
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
      step("Processing #{invd}") do
        invd.record_to_helios!
      end
    end
  end

  
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
end

last_sftp_check = Time.now-3600 # Pretend last check was two hours ago
returns_last_updated = Time.now-30
begin # Wait thirty seconds between checks.
  @for_month = Time.now.strftime("%Y") + '/' + (Time.now.strftime("%m").to_i).to_s
  @payment = {}
  @new_payments = {}
  @responses = {}
  @batch = EftBatch.find_or_create_by_for_month(@for_month)

  @return_files = Dir.open('EFT/'+@for_month).collect.reject {|a| a !~ /returns_.*\.csv$/}.sort.collect {|f| 'EFT/'+@for_month+'/'+f}

  # if !@return_files.blank?
  #   returns_new_updated = returns_last_updated
  #   @return_files.each do |f|
  #     mm = File.mtime(f)
  #     returns_new_updated = mm if mm > returns_last_updated
  #   end
  #   if returns_new_updated > returns_last_updated
  #     returns_last_updated = returns_new_updated
  #   else
      step "Loading Payments" do
        headers = true
        CSV::Reader.parse(File.open('EFT/'+@for_month+'/payment.csv', 'rb')) do |row|
          if headers
            headers = false
            next
          end
          goto = GotoTransaction.new_from_csv_row(row)
          @payment[goto.client_id.to_i] = goto
        end
      end

      step "Weaving in GotoBilling responses" do
        @return_files.each do |file| #Should be sorting by date
          step "Backing up Payments file" do
            CSV.open('EFT/'+@for_month+'/'+"payment_unmerged_#{Time.now.strftime("%d%H%M")}.csv", 'w') do |writer|
              writer << GotoTransaction.headers
              @payment.each_value do |goto|
                writer << goto.to_a
              end
            end
          end if false

          step "Weaving in #{file}" do
            File.rename(file, file+'.recorded')
            headers = true
            CSV::Reader.parse(File.open(file+'.recorded', 'rb')) do |row|
              if headers
                headers = false
                next
              end
              resp = Goto::Response.new(row)
              @responses[resp.client_id.to_i] = resp
              if @payment[resp.client_id.to_i]
                @payment[resp.client_id.to_i].response = @responses[resp.client_id.to_i]
                unless @payment[resp.client_id.to_i].recorded?
                  step "Recording Transaction #{resp.client_id} to Helios" do
                    GotoCsv::Extras.push_to_helios(@payment[resp.client_id.to_i])
                  end if false
                end
                @new_payments[resp.client_id.to_i] = @payment[resp.client_id.to_i]
              end
            end
          end

          step "Saving updated Payments file" do
            CSV.open('EFT/'+@for_month+'/payment_processed.csv', 'w') do |writer|
              writer << GotoTransaction.headers
              @new_payments.each_value do |goto|
                writer << goto.to_a
              end
            end
          end
        end
      end
  #   end
  # end

  step "Downloading files from GotoBilling" do
    download_sftp_files
    last_sftp_check = Time.now
  end if false && last_sftp_check < Time.now-1800 # More than an hour ago

end while sleep(150)
