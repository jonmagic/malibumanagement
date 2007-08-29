class HeliosClientsController < ApplicationController
  def search(live=false) # Searching for Clients - by first name, last name, or customer id.
    restrict('allow only admins') or begin
      self.class.layout nil
      @query = params[:query]
      if @query
        per_page = 30
        @total = Helios::ClientProfile.search_count(@query)
  logger.info "Total matched: #{@total}"
        @pages = Paginator.new self, @total, per_page, params[:page]
  logger.info "Limit: #{@pages.current.to_sql[0]}, Offset: #{@pages.current.to_sql[1]}"
        @clients = Helios::ClientProfile.search(@query, :limit => @pages.current.to_sql[0], :offset => @pages.current.to_sql[1])
  logger.info "Clients: #{@clients.length}"
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

  def exists
    restrict('allow only admins') or begin
      @client = Helios::ClientProfile.find(params[:id])
      @client_locations = Helios::ClientProfile.propogate_method(:find, @client.id)
      render :layout => false
    end
  end

  def destroy
    restrict('allow only admins') or begin
      Helios::ClientProfile.update_satellites = true # Ensures satellite databases are updated automatically.
      @client = Helios::ClientProfile.find(params[:id])
      @destroy_results = @client.destroy
      render :layout => false
    end
  end
end
