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
      amount = params[:amount]
      redirect_to :action => 'admin_eft' if amount.blank?
      # Do the work here
      GotoTransaction.search('', :filters => {'amount' => amount}).each do |unjust|
        # Change master to 18.88
        # Also Touches EFT on master
        if Helios::Eft.update_on_master(unjust.client_id, :Monthly_Fee => ZONE[:StandardMembershipPrice])
          # Touch ClientProfile on master
          Helios::ClientProfile.touch_on_master(unjust.client_id)
          unjust.update_attributes(:amount => ZONE[:StandardMembershipPrice])
        end
      end
      # * * * *
      redirect_to :action => 'admin_eft'
    end
  end

  private
    def get_batch
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (3.days.ago.strftime("%Y").to_i + 3.days.ago.strftime("%m").to_i/12).to_i.to_s + '/' + 3.days.ago.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
