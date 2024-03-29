class ClientMembersController < ApplicationController
  before_filter :get_batch

  def search(live=false) # Searching for Clients - by first name, last name, or customer id.
    restrict('allow only admins or store admins') or begin
      self.class.layout nil
      @query = params[:query]
      if @query
        per_page = 30
        bid = @batch.id
        filters = case params[:filter_by]
        when 'All'
          {}
        when 'Invalid'
          {'has_eft' => 1, 'goto_invalid' => '--- []'}
        when 'Missing EFT'
          {'no_eft' => 1}
        when 'Valid'
          {'has_eft' => 1, 'goto_valid' => '--- []'}
        when 'All Billed'
          {'has_eft' => 1, 'goto_valid' => '--- []'}
        when 'Completed'
          {'has_eft' => 1, 'goto_valid' => '--- []', 'completed' => ''}
        when 'Not Submitted'
          {'has_eft' => 1, 'goto_valid' => '--- []', 'ach_submitted' => false, 'tran_type' => 'ACH'}
        when 'In Progress'
          {'has_eft' => 1, 'goto_valid' => '--- []', 'in_progress' => ''}
        when 'Accepted'
          {'has_eft' => 1, 'goto_valid' => '--- []', 'status' => 'G'}
        when 'Declined'
          {'has_eft' => 1, 'goto_valid' => '--- []', 'status' => 'D'}
        when 'Processing Errors'
          {'status' => 'E'}
        else
          {}
        end
        filters = filters.merge('batch_id' => bid)
        filters = filters.merge('amount' => params[:amount]) if params[:amount]
        filters = filters.merge('location' => LOCATIONS.reject {|k,v| v[:domain] != accessed_domain}.keys[0]) unless params[:domain].blank?
        filters = filters.merge('tran_type' => params[:tran_type]) if params[:tran_type].to_s.length > 0
        mode = (params[:dcas] == 'true') ? :dcas : :gotobilling
        refund = (params[:refund] == 'true') ? true : false
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
              csv << (params[:gotoready] ? (mode == :dcas ? GotoTransaction.dcas_header_row(bid, LOCATIONS.reject {|k,v| v[:domain] != params[:domain]}.keys[0]) : GotoTransaction.csv_headers) : GotoTransaction.managers_csv_headers)
              @clients.reject { |c| params['cc_types'].is_a?(Array) ? !params['cc_types'].include?(c.dcas_card_type) : false }.reject {|c| refund ? !c.paid? : false}.each do |client|
                csv << (params[:gotoready] ? (mode == :dcas ? client.to_dcas_csv_row(:refund => refund) : client.to_csv_row(:refund => refund)) : client.to_managers_csv_row)
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
              page.flash("Removed VIP from client ##{gt.client_id}.", false, true, false)
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
              page.flash("Could not remove VIP from client ##{gt.client_id}. Please try again.", 'Ok', false, true)
            end
          }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html {raise}
        format.js {
          render :update do |page|
            page.flash("Client was not found.", 'Ok', false, true)
          end
        }
      end
    end
  end

  def reload_eft
    restrict('allow only store admins') or begin
      gt = GotoTransaction.find(params[:id])
      if gt.reload_eft!(LOCATIONS[LOCATIONS.reject {|k,v| v[:domain] != params[:domain]}.keys[0]][:name])
        respond_to do |format|
          format.html {
            flash[:notice] = "Reloaded EFT for client ##{gt.client_id} from #{LOCATIONS[gt.location][:name]}."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Reloaded EFT for client ##{gt.client_id} from #{LOCATIONS[gt.location][:name]}.")
            end
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = "Could not reload EFT from #{LOCATIONS[gt.location][:name]}."
            redirect_to store_eft_path()
          }
          format.js {
            render :update do |page|
              page.flash("Could not reload EFT from #{LOCATIONS[gt.location][:name]}.", 'Ok', false, true)
            end
          }
        end
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html {raise}
        format.js {
          render :update do |page|
            page.flash("Client was not found.", 'Ok', false, true)
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

    def get_batch
      @for_month = params[:for_month] ? Time.parse(params[:for_month]).strftime('%Y/%m') : (Time.yesterday.strftime("%Y").to_i + Time.yesterday.strftime("%m").to_i/12).to_i.to_s + '/' + Time.yesterday.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
      @batch = EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
    end
end
