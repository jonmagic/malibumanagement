# require 'net/ssh'
# require 'net/sftp'
require 'net/ftp'
require 'fileutils'
require 'faster_csv'
# require 'net/sftp/operations/write'
# Net::SFTP::Operations::Write::CHUNK_SIZE = 2048

class EftController < ApplicationController
  layout 'admin'
  before_filter :admin_pre_log_in
  before_filter :get_batch

  def regenerate_batch
    restrict('allow only admins') or begin
      @batch.update_attributes(:regenerate_now => 'all') unless @batch.locked
      redirect_to eft_path(:for_month => @for_month)
    end
  end

  def lock_batch
    @batch.update_attributes(:locked => true)
    redirect_to eft_path(:for_month => @for_month)
  end
  
  def admin_eft
    restrict('allow only admins')
  end
  
  def justify_amounts
    restrict('allow only admins') or begin
      return redirect_to :action => 'admin_eft' if params[:amount].blank?
      # Do the work here
      Helios::Eft.find_all_by_Monthly_Fee(params[:amount].to_f).each do |unjust|
        # Change to the standard amount
        unjust.update_attributes(
          :Monthly_Fee => ZONE[:StandardMembershipPrice],
          :UpdateAll => Time.now
        )
        # Update the corresponding GotoTransaction if exists
        if gt = GotoTransaction.find_by_client_id(unjust.id)
          gt.update_attributes(:amount => ZONE[:StandardMembershipPrice])
        end
      end
      # * * * *
      redirect_to :action => 'admin_eft'
    end
  end

  def submit_payments
    restrict('allow only admins') or begin
      return(render(:text => "<h4>Batch has not been locked!</h4>")) if !@batch.locked
      txt = ''
      Store.find(:all).each do |store|
        next if @batch.submitted[store.alias]
        next if store.config.nil?
        dcas = store.config[:dcas]
        # 1) Generate the file!
        path = "EFT/#{@batch.for_month}"
        FileUtils.mkpath(path+'/')
        cc_csv_name = "#{dcas[:company_user]}_cc_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
        ach_csv_name = "#{dcas[:company_user]}_ach_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
        csv_cc_local_filename = "#{path}/#{cc_csv_name}"
        csv_ach_local_filename = "#{path}/#{ach_csv_name}"
        @clients = GotoTransaction.search(@query, :filters => {'has_eft' => 1, 'goto_valid' => '--- []', 'batch_id' => @batch.id, 'location' => store.location_code})
        FasterCSV.open(csv_cc_local_filename, "w") do |cc_csv|
          cc_csv << GotoTransaction.dcas_header_row(@batch.id, store.location_code)
        FasterCSV.open(csv_ach_local_filename, "w") do |ach_csv|
          ach_csv << GotoTransaction.dcas_header_row(@batch.id, store.location_code)
          @clients.each do |client|
            ach_csv << client.to_dcas_csv_row if client.ach?
            cc_csv << client.to_dcas_csv_row if client.credit_card?
          end
        end
        end

        # 2) Upload the files!
        begin
          # SFTP
          # require 'net/sftp' # (install gem >= 2.0)
          # Net::SFTP.start(dcas[:sftp_host], dcas[:username], dcas[:password]) do |sftp|
          #   
          # end
          # ****
          ftp = Net::FTP.new(dcas[:host], dcas[:username], dcas[:password])
          ftp.chdir(dcas[:incoming_path])
          ftp.put(csv_cc_local_filename, cc_csv_name)
          ftp.put(csv_ach_local_filename, ach_csv_name)
          ftp.close
          txt += "#{store.config[:name]} - Uploaded<br />"
          @batch.submitted[store.alias] = true
          @batch.save
        rescue => e
          logger.error "FTP FAILED: #{e}"
          # If failed, immediately try deleting both of the files in case one made it or one made it partially.
          begin
            ftp = Net::FTP.new(dcas[:host], dcas[:username], dcas[:password])
            ftp.chdir(dcas[:incoming_path])
            ftp.delete(cc_csv_name)
            ftp.delete(ach_csv_name)
            ftp.close
          rescue => ef
            logger.error "FTP RESCUE FAILED: #{ef}"
          end
          txt += "#{store.config[:name]} FAILED<br />"
        end
      end
      render :text => "<h4>The following files have been uploaded:<br />#{txt}</h4>"
    end
  end

  def download_files
    restrict('allow only admins')
  end

  private
    def get_batch
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (3.days.ago.strftime("%Y").to_i + 3.days.ago.strftime("%m").to_i/12).to_i.to_s + '/' + 3.days.ago.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
