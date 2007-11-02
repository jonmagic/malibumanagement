# The Process:
# Check the sftp site every hour for files from gotobilling, download them and process them as responses to GotoTransactions.

require 'rubygems'
require 'net/ssh'
require 'net/sftp'
require 'goto_csv'

SFTP_CONFIG = {
  :host => 'sftp.malibutan.com' || 'sftp.malibu-tanning.com',
  :username => 'malibu2' || 'malibu',
  :password => 'gn1nn4t',
}
SFTP_CONFIG[:path] = "/home/#{SFTP_CONFIG[:username]}/gotobilling"

def step(description)
  puts(description+'...')
  ActionController::Base.logger.info(description+'...')
  begin
    yield if block_given?
    puts(description+" -> Done.")
    ActionController::Base.logger.info(description+" -> Done.")
  rescue => e
    puts("["+description+"] Caused Errors: {#{e}}")
    ActionController::Base.logger.info("["+description+"] Caused Errors: {#{e}}")
  end
end

def download_sftp_files
  files = []
  step("Connecting SFTP Session") do
    Net::SFTP.start(SFTP_CONFIG[:host], SFTP_CONFIG[:username], SFTP_CONFIG[:password]) do |sftp|
      handle = sftp.opendir(SFTP_CONFIG[:path])
      items = sftp.readdir(handle)
      files = items.collect {|i| i.filename}.reject {|a| a !~ /\.csv$/}
      sftp.close_handle(handle)
      files.each do |file|
        step("Downloading file #{file}") do
          sftp.remove(SFTP_CONFIG[:path]+'/'+file) if sftp.get_file(SFTP_CONFIG[:path]+'/'+file, "EFT/"+@for_month+'/'+file)
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
          end

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
                  end
                end
              end
            end
          end

          step "Saving updated Payments file" do
            CSV.open('EFT/'+@for_month+'/payment.csv', 'w') do |writer|
              writer << GotoTransaction.headers
              @payment.each_value do |goto|
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
  end if last_sftp_check < Time.now-1800 # More than an hour ago

end while sleep(150)
