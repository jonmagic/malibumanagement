require 'lib/ftps_implicit'
require 'fileutils'
require 'faster_csv'

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

# anything wrong, disconnect
# record each individual file that is uploaded, not per-store
# one-try each time, but ajax keeps retry-ing until it is done

  def submit_payments
    restrict('allow only admins') or begin
      return(render(:json => {:error => "Batch has not been locked!"}.to_json)) if !@batch.locked && params[:incoming_path].blank?

      # 1) For each location yet to be uploaded:
      #   1) Gather all clients-to-bill for this location.
      #   2) For each file type (ach, cc) yet to be uploaded:
      #     1) Create the file locally.
      #     2) Log in to FTPS.
      #     3) Create the 'uploading' folder if it's not already there.
      #     4) Delete the same filename from the 'uploading' folder if one exists.
      #     5) Upload the file into the 'uploading' folder.
      #     6) If we're still connected, check the file size of the file, then move it out of 'uploading' and mark file as completed.
      # 2) Respond with all results as JSON

      result = {}
      failed_count = 0
      Store.find(:all).each do |store|
        next if @batch.submitted[store.alias + '--ACH'] && @batch.submitted[store.alias + '--CC']
        next if store.config.nil?
        dcas = store.config[:dcas]
        incoming_path = params[:incoming_path] || dcas[:incoming_path]
        if incoming_path != dcas[:incoming_path]
          logger.info "Incoming Path set manually: #{incoming_path}"
        elsif !@batch.locked
          return(render(:json => {:error => "Batch has not been locked!"}.to_json))
        end

        path = "EFT/#{@batch.for_month}"
        FileUtils.mkpath(path+'/')

        @clients = GotoTransaction.search(@query, :filters => {'has_eft' => 1, 'goto_valid' => '--- []', 'batch_id' => @batch.id, 'location' => store.location_code})

        ['ACH', 'CC'].each do |type|
          file_key = "#{store.alias}--#{type}"
          next if @batch.submitted[file_key]
          # Generate the file!
          csv_name = "#{dcas[:company_user]}_#{type.downcase}_#{Time.now.strftime("%Y%m%d%H%M%S")}.csv"
          csv_local_filename = "#{path}/#{csv_name}"
          FasterCSV.open(csv_local_filename, "w") do |csv|
            csv << GotoTransaction.dcas_header_row(@batch.id, store.location_code)
            @clients.each do |client|
              csv << client.to_dcas_csv_row if (type == 'ACH' && client.ach?) || (type == 'CC' && client.credit_card?)
            end
          end

          # Upload the file!
          logged_in = false
          env_prepared = false

          #   1) Log in to FTPS.
          begin
            ftp = (dcas[:ftps] ? Net::FTPS::Implicit : Net::FTP).new(dcas[:host], dcas[:username], dcas[:password])
            logged_in = true
          rescue => e
            logger.error "FTP LOGIN FAILED: #{e}"
            result[file_key] = 'Failed to log in'
          end
          if logged_in
            begin
              #   2) Create the 'uploading' folder if it's not already there.
              ftp.mkdir('uploading') unless ftp.nlst.include?('uploading')
              # (create the incoming_path if it doesn't exist)
              ftp.mkdir(incoming_path) unless ftp.nlst.include?(incoming_path)

              ftp.chdir('uploading')

              #   3) Delete the same filename from the 'uploading' folder if one exists.
              ftp.delete("*.csv")
              env_prepared = true
            rescue => e
              logger.error "FTP FAILED BEFORE UPLOAD: #{e}\n#{e.backtrace.join("\n")}"
              result[file_key] = 'Failed before upload'
            end
          end
          if env_prepared
            begin
              #   4) Upload the file into the 'uploading' folder.
              ftp.put(csv_local_filename, csv_name)
              #   5) If we're still connected, check the file size of the file, then move it out of 'uploading' and mark file as completed.
              if ftp.nlst.include?(csv_name) && ftp.size(csv_name) == File.size(csv_local_filename)
                ftp.rename(csv_name, "../#{incoming_path}/#{csv_name}")
                @batch.submitted[file_key] = true
                @batch.save
                result[file_key] = "Uploaded."
              else
                result[file_key] = "Failed to upload (just wasn't there after uploading!)"
              end
            rescue => e
              logger.error "FTP FAILED DURING UPLOAD: #{e}\n#{e.backtrace.join("\n")}"
              result[file_key] = 'Failed during upload!'
            end
          end
          if logged_in
            begin
              ftp.quit
              ftp.close
            rescue => e
              logger.error "FTP FAILED DURING LOGOUT: #{e}\n#{e.backtrace.join("\n")}"
            end
          end
        end
      end

      #   6) Respond with the results as JSON
      render :json => result.to_json
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
