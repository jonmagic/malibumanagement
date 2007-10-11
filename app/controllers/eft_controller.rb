class EftController < ApplicationController
  layout 'admin'
  before_filter :set_month

  def generate_batch
    restrict('allow only admins') or begin
    # 1) Determine the month this will be active for
      time = Now.beginning_of_month
      batch = EftBatch.find_or_create_by_for_month(time.strftime("%Y/%m"))
      if !batch.submitted_at.blank?
        time = 5.weeks.from(time).beginning_of_month
        batch = EftBatch.find_or_create_by_for_month(time.strftime("%Y/%m"))
      end
    # 3) Redirect to view_batch_stats of that month
      redirect_to eft_path(:action => 'view_batch_stats', :for_month => batch.for_month)
    end
  end
  
  def view_batch_stats
    restrict('allow only admins') or begin
      # Just view the numbers in the specified month's EftBatch record
logger.info(EftBatch.find_by_for_month(@for_month))
      @batch = EftBatch.find_or_create_by_for_month(@for_month)
    end
  end
  
  def submit_batch
    restrict('allow only admins') or begin
      @batch = EftBatch.find_or_create_by_for_month(Now.strftime("%Y/%m"))
      @batch.submit_for_payment!
      # Return a nice "Yeah it's submitted" indication .. then show "Batch Submitted, ## Payments pending" instead of Submit Batch link.
    end
  end

  private
    def set_month
      @for_month = params[:for_month]
      @for_month ||= Now.strftime("%Y/%m")
    end
end

class Fixnum
  # Adds one number to another, but rolls over to the beginning of the range whenever it hits the top of the range.
  def cyclical_add(addend, cycle_range)
    raise ArgumentError, "#{self} is not within range #{cycle_range}!" if !cycle_range.include?(self)
    while(self+addend > cycle_range.last)
      addend -= cycle_range.last-cycle_range.first+1
    end
    return self+addend
  end
end
