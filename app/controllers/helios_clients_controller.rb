class HeliosClientsController < ApplicationController
  def search(live=false) # Searching for Clients - by first name, last name, or customer id.
    restrict('allow only admins') or begin
      self.class.layout nil
      @query = params[:query]
      if @query
        per_page = 30
        @total = Helios::ClientProfile.search_count(@query)
        @pages = Paginator.new self, @total, per_page, params[:page]
        @clients = Helios::ClientProfile.search(@query, :limit => @pages.current.to_sql[0], :offset => @pages.current.to_sql[1])
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
      respond_to do |format|
        format.js
      end
    end
  end
end
