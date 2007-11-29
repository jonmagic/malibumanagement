class EftController < ApplicationController
  layout 'admin'
  before_filter :get_batch

  def regenerate_batch
    restrict('allow only admins') or begin
      @batch.update_attributes(:regenerate_now => 'all')
      redirect_to eft_path(:for_month => @for_month)
    end
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
        store_name = LOCATIONS[LOCATIONS.reject {|k,v| v[:domain] != params[:domain]}.keys[0]][:name]
        if unjust.client && unjust.client.eft && unjust.client.eft.update_on_slave(store_name, :Monthly_Fee => ZONE[:StandardMembershipPrice], :Last_Mdt => Time.now)
          if self.client
            # Touch ClientProfile on current store
            self.client.touch_on_slave(store_name)
            if self.client.eft
              # Touch EFT on current store
              self.client.eft.touch_on_slave(store_name)
            end
          end
          unjust.update_attributes(:amount => ZONE[:StandardMembershipPrice])
        end
      end
      # * * * *
      redirect_to :action => 'admin_eft'
    end
  end

  def location_csv
    restrict('allow only admins') or begin
      stream_csv(params[:location] + '_payments.csv') do |csv|
        csv << GotoTransaction.managers_headers
        headers = true
        CSV::Reader.parse(File.open('EFT/' + @for_month + '/payment.csv', 'rb')) do |row|
          if headers
            headers = false
            next
          end
          goto = GotoTransaction.new_from_csv_row(row)
          csv << goto.to_managers_a if goto.location == params[:location]
        end
      end
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
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
