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

      FileUtils.mkpath("EFT/#{@batch.for_month}/")
      # limit to 5 file attempts before returning to AJAX. AJAX should immediately call this action back to continue.
      attempt_count = 0

      result = {}
      Store.find(:all).each do |store|
        @batch.reload
        return(render(:json => result.merge(:error => "Batch was unlocked in the middle of submitting!").to_json)) unless @batch.locked
        next if @batch.submitted?(store) || store.config.nil?
        dcas = store.config[:dcas]
        # Verify that ALL of the required information is present.
        next unless dcas[:username] && dcas[:password] && dcas[:company_alias] && dcas[:company_username] && dcas[:company_password]

        # Set up DCAS for uploading
        dcas_client = DCAS::Client.new(
                   :username => dcas[:username],
                   :password => dcas[:password],
                   :company_alias => dcas[:company_alias],
                   :company_username => dcas[:company_username],
                   :company_password => dcas[:company_password],
                   :cache_location => "EFT/#{@batch.for_month}"
                  )

        topay = GotoTransaction.search(@query, :filters => {'has_eft' => 1, 'goto_valid' => '--- []', 'batch_id' => @batch.id, 'location' => store.location_code})

        # Create the payment batches
        cc_batch = dcas_client.new_batch(Time.parse(@batch.for_month).strftime("%y%m"))
        ach_batch = dcas_client.new_batch(Time.parse(@batch.for_month).strftime("%y%m"))
        # And populate them
        topay.each do |payment|
          # csv << client.to_dcas_csv_row if (type == 'ACH' && client.ach?) || (type == 'CC' && client.credit_card?)
          # ACH: client_id, client_name, amount, account_type, routing_number, account_number, check_number
          #  CC: client_id, client_name, amount, card_type, credit_card_number, expiration
          if payment.ach?
            ach_batch << DCAS::AchPayment.new(
                           payment.client_id, payment.name_on_card, payment.amount,
                           payment.dcas_bank_account_type, payment.bank_routing_number,
                           payment.bank_account_number, payment.get_check_number
                         )
          else
            cc_batch  << DCAS::CreditCardPayment.new(
                           payment.client_id, payment.name_on_card,
                           payment.amount, payment.dcas_card_type, payment.credit_card_number,
                           payment.expiration.nil? ? nil : (payment.expiration[0,2] + '/20' + payment.expiration[2,2])
                         )
          end
        end
        
        # Submit the batches
        result[ach_batch.filename] = 'Waiting...' if attempt_count == 5
        begin # ACH batch submit
          result[ach_batch.filename] = dcas_client.submit_batch!(ach_batch, @batch) ? 'Uploaded.' : 'Failed.'
          attempt_count += 1
        end unless attempt_count == 5
        result[cc_batch.filename] = 'Waiting...' if attempt_count == 5
        begin # CC batch submit
          result[cc_batch.filename] = dcas_client.submit_batch!(cc_batch, @batch) ? 'Uploaded.' : 'Failed.'
          attempt_count += 1
        end unless attempt_count == 5

      end # end Store.each

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
