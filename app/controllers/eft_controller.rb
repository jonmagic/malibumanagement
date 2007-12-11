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
      redirect_to :action => 'admin_eft' if params[:amount].blank?
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

  private
    def get_batch
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (3.days.ago.strftime("%Y").to_i + 3.days.ago.strftime("%m").to_i/12).to_i.to_s + '/' + 3.days.ago.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
