class StoreEftController < ApplicationController
  layout 'store'
  before_filter :get_batch

  def regenerate_batch
    restrict('allow only store admins') or begin
      @batch.update_attributes(:regenerate_now => LOCATIONS.reject {|k,v| v[:domain] != accessed_domain}.keys[0])
      redirect_to store_eft_path(:for_month => @for_month)
    end
  end
  
  def managers_eft
    restrict('allow only store admins')
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
