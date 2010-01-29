require 'net/ftps_implicit'
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
    restrict('allow only admins') or begin
      if params[:free_dcas_lock].to_s == 'true'
        Store.find(:all).each do |store|
          @batch.submitted.each_key do |key|
            @batch.submitted[key] = false if @batch.submitted[key] == 'uploading'
          end
        end
        @batch.save
      end
    end
  end
  
  def justify_amounts
    restrict('allow only admins') or begin
      return redirect_to(:action => 'admin_eft') if params[:amount].blank?
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
      return(render(:json => {:error => "Batch has not been locked!"}.to_json)) if !@batch.locked && params[:outgoing_bucket].blank?
      

      FileUtils.mkpath("EFT/#{@batch.for_month}/")

      result = {}
      Store.find(:all).each do |store|
        @batch.reload
        next if @batch.submitted?(store) || store.config.nil?
        # Verify that ALL of the required information is present.
        next unless store.config[:dcas][:username] && store.config[:dcas][:password] && store.config[:dcas][:company_alias] && store.config[:dcas][:company_username] && store.config[:dcas][:company_password]
        store.dcas.cache_location = "EFT/#{@batch.for_month}"
        store.dcas.outgoing_bucket = params[:outgoing_bucket] if params[:outgoing_bucket]

        if store.dcas.outgoing_bucket != DCAS::DEFAULT_OUTGOING_BUCKET
          logger.info "Outgoing Bucket set manually: #{store.dcas.outgoing_bucket}"
        elsif !@batch.locked
          return(render(:json => result.merge(:error => "Batch was unlocked in the middle of submitting!").to_json)) unless @batch.locked || params[:outgoing_bucket]
        end

        # Skip early if we can.
        if @batch.submit_locked?(store.config[:dcas][:company_username]+'_achpayment.csv') && @batch.submit_locked?(store.config[:dcas][:company_username]+'_creditcardpayment.csv')
          result[store.config[:dcas][:company_username]+'_achpayment.csv'] = 'Skipped.'
          result[store.config[:dcas][:company_username]+'_creditcardpayment.csv'] = 'Skipped.'
          next
        end

        # Get all of the payments we need to run
        topay = GotoTransaction.search(@query, :filters => {'has_eft' => 1, 'goto_valid' => '--- []', 'batch_id' => @batch.id, 'location' => store.location_code})

        # Create the payment batches
        cc_batch = store.dcas.new_batch(Time.parse(@batch.for_month).strftime("%y%m"))
        ach_batch = store.dcas.new_batch(Time.parse(@batch.for_month).strftime("%y%m"))
        # And populate them
        topay.each do |txn|
          (txn.ach? ? ach_batch : cc_batch) << txn.to_dcas_payment
        end

        # Submit the batches
        begin # ACH batch submit
          if @batch.submit_locked?(ach_batch.filename) || ach_batch.payments.empty?
            result[ach_batch.filename] = 'Skipped.'
          else
            result[ach_batch.filename] = store.dcas.submit_batch!(ach_batch, @batch) ? 'Uploaded.' : 'Failed.'
          end
        end
        begin # CC batch submit
          if @batch.submit_locked?(cc_batch.filename) || cc_batch.payments.empty?
            result[cc_batch.filename] = 'Skipped.'
          else
            result[cc_batch.filename] = store.dcas.submit_batch!(cc_batch, @batch) ? 'Uploaded.' : 'Failed.'
          end
        end

      end # end Store.each

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
