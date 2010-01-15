require 'rubygems'

if ARGV.include?('--help')
  puts "Options:\n\t#{['help','no-delete', 'no-download', 'only-download', 'dry-run', 'no-cc', 'no-ach', 'cc-only', 'ach-only'].join("\n\t--")}"
  exit
end

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
FileUtils.mkpath(@path + 'returns/')

require 'net/ftps_implicit' # Should pull this straight from dcas-ruby.
step("Downloading DCAS files for #{@batch.for_month}.") do
  files = []
  Store.find(:all).each do |store|
    next if @batch.submitted?(store).nil? # skip entirely if no files were submitted for this store
    next unless store.config.is_a?(Hash)
    dcas = store.config[:dcas]
    user_suffix = dcas[:username].match(/(?:malibu|maltan|malent)?(.*)(?:VT)?/)[1]
    store_files = []
    ftp = nil
    step("Downloading from DCAS as #{store.config[:name]}",:retry => 2) do
      # SFTP
      # require 'net/sftp' # (install gem >= 2.0)
      # Net::SFTP.start(dcas[:sftp_host], dcas[:username], dcas[:password]) do |sftp|
      #   sftp.dir.foreach(dcas[:outgoing_path] + '/*.csv') do |entry| # includes
      #     # entry.?
      #   end
      # end
      # ****
      ftp = (dcas[:ftps] ? Net::FTPS::Implicit : Net::FTP).open(dcas[:host], dcas[:username], dcas[:password])
      ftp.chdir(dcas[:outgoing_path])
      dfiles = ftp.list('*.csv')
      dfiles.each do |filels|
        size, file = filels.split(/ +/)[4], filels.split(/ +/)[8..-1].join(' ')
        localfile = @path + 'returns/' + user_suffix + '_' + file
        if File.exists?(localfile) && size == File.size(localfile).to_s
          report "Already downloaded file #{file}"
        else
          step("Downloading file #{file}") do
            ftp.get(file, localfile)
            ftp.delete(file) unless ARGV.include?('--no-delete')
            files << file
          end
        end
      end
      ftp.quit
      ftp.close
    end
  end
  files.length
end unless ARGV.include?('--no-download')

require 'csv'
step("Reading return files into MySQL") do
  all_files = Dir.open(@path + 'returns/').collect.sort
  # There are 5 different kinds of files to deal with.
  # 1) Create (disregard): /create\d+/ - probably BEING created, then is renamed?
  # 2) Initial CA answers: /#{filename}_\d+_CA.CSV/
  # 3) Final CC answers:   /#{filename}_\d+_CC.CSV/
  # 4) Final CA answers:   Returns#{filename}.csv
  # 5) Entire file rejected: exact same filename back, with a message (ex. "9099 Logon Failed")
  create_files = all_files.select {|f| f =~ /^create\d+$/}
  ach_processed = all_files.select {|f| f =~ /_\d+_CA\.[cC][sS][vV]$/}
  final_cc = all_files.select {|f| f =~ /_\d+_CC\.[cC][sS][vV]$/}
  final_ach = all_files.select {|f| f =~ /_Returns.*_\d+\.[cC][sS][vV]$/}
  leftover_files = all_files - create_files - ach_processed - final_cc - final_ach

  step("Processing Credit Card responses") do
    final_cc.each do |ccfile|
      step("Reading file #{ccfile}") do
        debug_step "Continue?", 'each-cc-file' if ARGV.include?('--debug-step')
        clients = {}
        CSV::Reader.parse(File.open(@path + 'returns/' + ccfile, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |ccrow|
          debug_step "Next line: #{ccrow.inspect} Continue?", 'each-cc-line' if ARGV.include?('--debug-step')
          # Could be simply '9999' -- error!
          begin
            if ccrow == ['9999']
              # report "Row with 9999"
              next
            end
            # Otherwise, it is in this format:
            # CC,AccountNumber,ReturnCode,ReasonDescription,CustTraceCode
            response = DcasResponse.new(@batch.id, ccrow)
            if '20' + ccrow[4][0..1] + '/' + ccrow[4][2..3] != @batch.for_month
              report "CustTraceCode #{ccrow[4]} mentions an invalid Batch!!"
              next
            end
            invalid = response.invalid?
            if response.transaction
              # report "Copying client #{response.inspect} to MySQL..." if rand(30) == 15
              response.record_to_transaction! unless ARGV.include?('--dry-run')
            else
              invalid = "Transaction couldn't be matched up."
            end
            clients[response.client_id] = response
            report "Row :#{ccrow.join(',')}: #{invalid}" if invalid
          rescue => e
            puts(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{ccrow.inspect} (#{e})")
            ActionController::Base.logger.info(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{ccrow.inspect} (#{e})") rescue nil
          end
        end
      end
    end
  end unless ARGV.include?('--no-cc') || ARGV.include?('--ach-responses-only') || ARGV.include?('--ach-returns-only')

  step("Processing ACH responses") do
    ach_processed.each do |achfile|
      step("Reading ACH Response file #{achfile}") do
        debug_step "Continue?", 'each-ach-file' if ARGV.include?('--debug-step')
        clients = {}
        CSV::Reader.parse(File.open(@path + 'returns/' + achfile, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |achrow|
          debug_step "Next line: #{achrow.inspect} Continue?", 'each-ach-line' if ARGV.include?('--debug-step')
          begin
            response = DcasAchResponse.new(@batch.id, achrow)
            if '20' + achrow[4][0..1] + '/' + achrow[4][2..3] != @batch.for_month
              report "CustTraceCode #{achrow[4]} mentions an invalid Batch!!"
              next
            end
            invalid = response.invalid?
            if response.transaction
              # report "Copying client #{response.inspect} to MySQL..." if rand(30) == 15
              response.record_to_transaction! unless ARGV.include?('--dry-run')
            else
              invalid = "Transaction couldn't be matched up."
            end
            clients[response.client_id] = response
            report "Row :#{achrow.join(',')}: #{invalid}" if invalid
          rescue => e
            puts(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{achrow.inspect} (#{e})")
            ActionController::Base.logger.info(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{achrow.inspect} (#{e})") rescue nil
          end
        end
      end
    end
  end unless ARGV.include?('--no-ach-responses') || ARGV.include?('--cc-only') || ARGV.include?('--ach-returns-only')

  step("Processing ACH returns") do
    debug_step "Continue?" if ARGV.include?('--debug-step')
    # 1) Run through ALL ACH GotoTransactions and make sure they all have a status (default: 'G' - Accepted)
    # ach = GotoTransaction.find(:all, :conditions => ['batch_id=? AND tran_type=?',@batch.id,'ACH'])
    # ach.each {|g| g.update_attributes(:status => 'G') unless g.status.to_s != ''}
    # 2) Run through Returns files to mark ACH's
    final_ach.each do |achfile|
      step("Reading ACH Return file #{achfile}") do
        debug_step "Continue?", 'each-ach-file' if ARGV.include?('--debug-step')
        clients = {}
        CSV::Reader.parse(File.open(@path + 'returns/' + achfile, 'rb').map {|l| l.gsub(/[\n\r]+/, "\n")}.join) do |achrow|
          debug_step "Next line: #{achrow.inspect} Continue?", "each-ach-return-line #{achrow[5]}" if ARGV.include?('--debug-step')
          begin
            response = DcasAchReturn.new(@batch.id, achrow)
            if '20' + achrow[7][0..1] + '/' + achrow[7][2..3] != @batch.for_month
              report "CustTraceCode #{achrow[7]} mentions an invalid Batch!!"
              next
            end
            invalid = response.invalid?
            if response.transaction
              # report "Copying client #{response.inspect} to MySQL..." if rand(30) == 15
              response.record_to_transaction! unless ARGV.include?('--dry-run')
            else
              invalid = "Transaction couldn't be matched up."
            end
            clients[response.client_id] = response
            report "Row :#{achrow.join(',')}: #{invalid}" if invalid
          rescue => e
            puts(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{achrow.inspect} (#{e})")
            ActionController::Base.logger.info(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "** ERROR Processing row: #{achrow.inspect} (#{e})") rescue nil
          end
        end
      end
    end
  end unless ARGV.include?('--no-ach-returns') || ARGV.include?('--cc-only') || ARGV.include?('--ach-responses-only')
  ''
end unless ARGV.include?('--only-download')
