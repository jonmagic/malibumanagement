class ClientMembersController < ApplicationController
  def search(live=false) # Searching for Clients - by first name, last name, or customer id.
    restrict('allow only admins or store admins') or begin
      self.class.layout nil
      @query = params[:query]
      if @query
        per_page = 30
        per_page = 9999999 if params[:format] == 'csv'
        bid = EftBatch.find_or_create_by_for_month(Time.parse(params[:Time][:next_month]).strftime("%Y/%m")).id
        filters = case params[:filter_by]
        when 'All'
          {}
        when 'Invalid'
          {'has_eft' => 1, 'goto_invalid' => '%--- []%'}
        when 'Missing EFT'
          {'no_eft' => 1, 'goto_valid' => '%--- []%'}
        when 'Valid'
          {'has_eft' => 1, 'goto_valid' => '%--- []%'}
        end
        filters = filters.merge('batch_id' => bid, 'location' => LOCATIONS.reject {|k,v| v[:domain] != accessed_domain}.keys[0])
        @total = GotoTransaction.search_count(@query, :filters => filters)
        @pages = Paginator.new self, @total, per_page, params[:page]
        @clients = GotoTransaction.search(@query, :filters => filters, :limit => @pages.current.to_sql[0], :offset => @pages.current.to_sql[1])
        respond_to do |format|
          format.html # Render the template file
          format.js   # Render the rjs file
          format.csv {
            stream_csv(LOCATIONS[LOCATIONS.reject {|k,v| v[:domain] != params[:domain]}.keys[0]][:name].underscore + '-' + params[:filter_by].to_s.underscore + '.csv') do |csv|
              csv << GotoTransaction.managers_csv_headers
              @clients.each do |client|
                csv << client.to_managers_csv_row
              end
            end
          }
        end
      else
        render :nothing => true
      end
    end
  end
  def livesearch
    search(true)
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
end
