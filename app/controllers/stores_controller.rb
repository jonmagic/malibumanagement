class StoresController < ApplicationController
  before_filter :current_user

  in_place_edit_for :store, 'friendly_name'
  in_place_edit_for :store, 'address'
  in_place_edit_for :store, 'telephone'
  in_place_edit_for :store, 'contact_person'
  in_place_edit_for :store, 'gcal_url'
  layout 'store'

# AccessControl:
#  dashboard: anyone logged in to the current accessed_store
#  profile:   only the current accessed_store's store admin
#  update:    only the current accessed_store's store admin

  # GET /:domain/dashboard
  def dashboard
    restrict('allow only store users')
  end

  def work_schedule
    restrict('allow only store users') or begin
      @store = current_store
      redirect_to admin_dashboard_path if @store.nil? || @store.gcal_url.blank?
      # Need to pull this value from @store.gcal_url
      # @cal = Calendar.new('https://www.google.com/calendar/ical/yanno.org_lf810kkm8475qm1p5c1ncmilec%40group.calendar.google.com/private-28518e4e7f49d0470d59ba10047ce78b/basic.ics')
      @cal = Calendar.new(@store.gcal_url)
      redirect_to store_dashboard_path if @cal.nil?
      @start = params[:start] ? Time.utc(params[:start].split('-')[0], params[:start].split('-')[1], params[:start].split('-')[2]) : Time.now
    end
  end

#This should be operational for store admins to view and edit their account
  def profile
    restrict('allow only store admins') or begin
      @store = current_store
    end
  end

#This needs to be locked down to do only what it should be allowed to do
# An Ajax-only action.
  def update
    restrict('allow only store admins') or begin
      @store = Store.find(params[:id])
      log = Log.new(:log_type => 'update:Store', :data => {:old_attributes => @store.attributes.changed_values(params[:store])}, :object => @store, :agent => current_user)
logger.error "Created log: #{log}\n"
      respond_to do |format|
  #This doesn't update the FormTypes association if all of them are unchecked...?
  logger.error "Current user #{@current_user}...\n"
        if (@store.valid?) &&  @store.update_attributes(params[:store])
          logger.error "Current user #{@current_user}...\n"
          log.save
          flash[:notice] = "Store was successfully updated."
          format.html { redirect_to store_url(@store) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @store.errors.to_xml }
        end
      end
    end
  end

end
