require 'lib/ftps_implicit'
require 'fileutils'
require 'faster_csv'

class StoreEftController < ApplicationController
  layout 'store'
  before_filter :store_pre_log_in
  before_filter :get_batch

  def regenerate_batch
    restrict('allow only store admins') or begin
      @batch.update_attributes(:regenerate_now => LOCATIONS.reject {|k,v| v[:domain] != accessed_domain}.keys[0]) unless @batch.locked
      redirect_to store_eft_path(:for_month => @for_month)
    end
  end
  
  def managers_eft
    restrict('allow only store admins')
  end

  def refund_clients
    restrict('allow only store admins') or begin
      return(render(:text => "<h4>Batch has not been locked!</h4>")) if !@batch.locked
      txt = ''
      next if current_store.config.nil?
      dcas = current_store.config[:dcas]
      # 1) Generate the file!
      path = "EFT/#{@batch.for_month}"
      FileUtils.mkpath(path+'/')
      csv_name = "#{dcas[:company_user]}_refund_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
      csv_local_filename = "#{path}/#{csv_name}"
      @clients = GotoTransaction.search(@query, :filters => {'has_eft' => 1, 'goto_valid' => '--- []', 'client_id' => params[:client_id], 'batch_id' => @batch.id, 'location' => current_store.location_code})
      client_count = 0
      FasterCSV.open(csv_local_filename, "w") do |csv|
        csv << GotoTransaction.dcas_header_row(@batch.id, current_store.location_code)
        @clients.each do |client|
          client_count += 1
          csv << client.to_dcas_csv_row(:refund => true)
        end
      end

      # 2) Upload the files!
      if client_count > 1
        return render(:text => "<em>ERROR == shouldn't refund more than one person at a time.</em>")
      end
      begin
        ftp = (dcas[:ftps] ? Net::FTPS::Implicit : Net::FTP).new(dcas[:host], dcas[:username], dcas[:password])
        ftp.chdir(dcas[:incoming_path])
        ftp.put(csv_local_filename, csv_name)
        ftp.quit
        ftp.close
        txt += "Refund submitted"
        @clients.each do |client|
          client.status = 'h'
          client.save
        end
      rescue => e
        logger.error "FTP (Refund) FAILED: #{e}"
        txt += "Refund FAILED<br />"
      end
      render :text => "<em>#{txt}</em>"
    end
  end

  private
    def stream_csv(filename)
      require 'fastercsv'
      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers["Content-type"] = "text/plain" 
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
        headers['Expires'] = "0" 
      else
        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
      end
      render :text => Proc.new { |response, output| yield FasterCSV.new(output, :row_sep => "\r\n") }
    end

    def get_batch
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (Time.yesterday.strftime("%Y").to_i + Time.yesterday.strftime("%m").to_i/12).to_i.to_s + '/' + Time.yesterday.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
