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
          {}
        when 'Invalid'
          {'has_eft' => 1, 'goto_invalid' => '--- []'}
        when 'Missing EFT'
          {'no_eft' => 1}
        when 'Valid'
          {'has_eft' => 1, 'goto_valid' => '--- []'}
        else
          {}
        end
        filters = filters.merge('batch_id' => bid)
        filters = filters.merge('amount' => params[:amount]) if params[:amount]
        filters = filters.merge('location' => LOCATIONS.reject {|k,v| v[:domain] != accessed_domain}.keys[0]) unless params[:domain].blank?
        if params[:format] == 'csv'
          @clients = GotoTransaction.search(@query, :filters => filters)
        else
          @total = GotoTransaction.search_count(@query, :filters => filters)
          @pages = Paginator.new self, @total, per_page, params[:page]
          @clients = GotoTransaction.search(@query, :filters => filters, :limit => @pages.current.to_sql[0], :offset => @pages.current.to_sql[1])
        end
        respond_to do |format|
          format.html # Render the template file
          format.js   # Render the rjs file
          format.csv {
            domain_name = params[:domain].blank? ? 'malibu' : LOCATIONS[LOCATIONS.reject {|k,v| v[:domain] != params[:domain]}.keys[0]][:name].underscore
            send_csv(domain_name + '-' + params[:filter_by].to_s.underscore + '.csv') do |csv|
              csv << (params[:gotoready] ? GotoTransaction.csv_headers : GotoTransaction.managers_csv_headers)
              @clients.each do |client|
                csv << (params[:gotoready] ? client.to_csv_row : client.to_managers_csv_row)
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

  def remove_vip
    restrict('allow only store admins') or begin
      gt = GotoTransaction.find(params[:id])
      if gt.remove_vip!
        respond_to do |format|
          format.html {
            flash[:notice] = "Removed VIP from client ##{gt.client_id}."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Removed VIP from client ##{gt.client_id}.", 'Ok')
              page["client_listing_#{params[:id]}"].remove
            end
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = "Could not remove VIP from client ##{gt.client_id}. Please try again."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Could not remove VIP from client ##{gt.client_id}. Please try again.", 'Ok')
            end
          }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html {raise}
        format.js {
          render :update do |page|
            page.flash("Client was not found.")
          end
        }
      end
    end
  end

  def reload_eft
    restrict('allow only store admins') or begin
      gt = GotoTransaction.find(params[:id])
      if gt.reload_eft!
        respond_to do |format|
          format.html {
            flash[:notice] = "Reloaded VIP for client ##{gt.client_id} from #{LOCATIONS[gt.location][:name]}."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Reloaded VIP for client ##{gt.client_id} from #{LOCATIONS[gt.location][:name]}.")
            end
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = "Could not reload VIP from #{LOCATIONS[gt.location][:name]}."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Could not reload VIP from #{LOCATIONS[gt.location][:name]}.")
            end
          }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html {raise}
        format.js {
          render :update do |page|
            page.flash("Client was not found.")
          end
        }
      end
    end
  end

  private
    def send_csv(filename)
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
      output_csv = [] #Let the method run all before we start rendering
      yield output_csv
      csv_push = Proc.new {|fcsv|
        logger.info "Should be a FasterCSV: #{fcsv.inspect}"
        output_csv.each do |oo|
          fcsv << oo
        end
        fcsv
      } #set up the call that just pushes the whole thing at once
      render :text => Proc.new { |response, output| csv_push.call(FasterCSV.new(output, :row_sep => "\r\n"))}
    end

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
