class ClientMembersController < ApplicationController
  def search(live=false) # Searching for Clients - by first name, last name, or customer id.
    restrict('allow only admins or store admins') or begin
      self.class.layout nil
      @query = params[:query]
      if @query
        per_page = 30
        bid = EftBatch.find_or_create_by_for_month(Time.parse(params[:Time][:next_month]).strftime("%Y/%m")).id
        filters = case params[:filter_by]
        when 'All'
          {'batch_id' => bid}
        when 'Invalid'
          {'has_eft' => 1, 'goto_invalid' => '%--- []%', 'batch_id' => bid}
        when 'Missing EFT'
          {'no_eft' => 1, 'goto_valid' => '%--- []%', 'batch_id' => bid}
        when 'Valid'
          {'has_eft' => 1, 'goto_valid' => '%--- []%', 'batch_id' => bid}
        end
        @total = GotoTransaction.search_count(@query, :filters => filters)
        @pages = Paginator.new self, @total, per_page, params[:page]
        @clients = GotoTransaction.search(@query, :filters => filters, :limit => @pages.current.to_sql[0], :offset => @pages.current.to_sql[1])
        respond_to do |format|
          format.html # Render the template file
          format.js   # Render the rjs file
        end
      else
        render :nothing => true
      end
    end
  end
  def livesearch
    search(true)
  end
end
