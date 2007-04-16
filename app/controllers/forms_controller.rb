class FormsController < ApplicationController
  layout 'store'
  before_filter :add_form_restrictions

  def add_form_restrictions
    add_restriction('allow only if valid form type', !current_store.form_model(params[:form_type]).nil?) {
      flash[:notice] = "Attempted access of unauthorized form type!"
    } if logged_in? and current_user.is_store_user?
  end

# This is sample code for uploading a file and saving it to disk.
# File.open(”/Users/db/_dev/rails/videos/swing.mov”, “w”){|f|f.write(@params[”video”].read)}
# params[:file_uploaded] will contain a File object, or StringIO if empty

  def index
    restrict('allow only store users') or begin
      if params[:form_status].nil?
        redirect_to store_forms_by_status_path(:form_status => 'drafts')
      elsif params[:form_status] == 'archived'
        render :action => 'archive_view'
      else
        if params[:form_status] == 'all'
          @my_forms = current_user.form_instances
          @others_forms = current_user.others_form_instances
        else
          @my_forms = current_user.forms_with_status(params[:form_status])
          @others_forms = current_user.others_forms_with_status(params[:form_status])
        end
      end
    end
  end

  def archive_view
  end

#There should be three fields here: Store, Date
  def search(live=false)
    user    = nil
    date    = nil

    user    = "%" + params[:user_field]    + "%" if !params[:user_field].nil? and params[:user_field].length > 0
    date = (!params[:Time][:tomorrow].nil? and params[:Time][:tomorrow].length > 0) ? params[:Time][:tomorrow] : Time.tomorrow
#Learn how to handle Dates in rails' forms
    # date    = params[:date_field].nil? ? Date.new. : params[:date_field]

# logger.error "D: #{store}/#{params[:store_field]}; U: #{user}/#{params[:user_field]}; T: #{date}/#{params[:Time][:now]}\n"

    tables = ['form_instances']
    tables.push('users') unless user.nil?

    matches = ["form_instances.store_id=:store_id AND form_instances.status_number=4 AND form_instances.created_at < :date"] #Put the date field in first by default - there will always be a date to search for.
    matches.push('form_instances.user_id=users.id') unless user.nil?
    matches.push('users.friendly_name LIKE :user') unless user.nil?

    @form_values = {:Time => {:tomorrow => date}} #put the date field in first by default - there will always be a date to search for.
    @values = {:date => date, :store_id => current_store.id}
    @form_values.merge!({:user_field => params[:user_field]}) unless user.nil?
    @values.merge!({:user => user}) unless user.nil?

# SELECT form_instances.* FROM form_instances,stores,users WHERE form_instances.store_id=stores.id AND form_instances.user_id=users.id AND stores.friendly_name LIKE :store AND users.friendly_name LIKE :user

    @result_pages, @results = paginate_by_sql(FormInstance, ["SELECT form_instances.* FROM " + tables.join(',') + " WHERE " + matches.join(' AND ') + " ORDER BY form_instances.created_at DESC", @values], 30)
    @search_entity = @results.length == 1 ? "Archived Form" : "Archived Forms"
    render :layout => false
  end
  def live_search
    search(true)
  end

#This is hit first. The form instance is created and then redirects to the editing ('draft') of the created form.
  def new
    restrict('allow only store users') or begin
      return redirect_to(store_dashboard_url) if params[:form_type] == 'chooser'
logger.error "Current Model: #{current_form_model}"
      @form = !FormType.find_by_name(params[:form_type]).can_have_multiple_drafts && current_store.drafts_of_type(params[:form_type]).count > 0 ? current_store.drafts_of_type(params[:form_type])[0] : FormInstance.new(
        :user => current_user,
        :store => current_store,
        :form_type => current_form_model, #Automatically creates the connected form data via the appropriate (given) model
        :status => 'draft'
      )
      if @form.save
        redirect_to store_forms_url(:form_status => 'draft', :form_type => @form.data_type, :action => 'draft', :form_id => @form.id)
      else
        render :action => 'draft'
      end
    end
  end

#Actually think of this as 'edit'
  def draft
    restrict('allow only store users') or begin
#Redirect to view the form if not allowed to edit
# restrict('')
# * * * *
      @form_type = params[:form_type]
      return redirect_to(store_dashboard_url) if @form_type == 'chooser'
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      @data = @form.data
      # Drop the status down to draft! -- only if reeditable!
      if !(@form.status == 'draft') && @form.form_type.reeditable
        @form.status = 'draft'
        @form.save
      end
      @values = @data
    end
  end

#This is for submitting edits. This is an ajax-specific function, normally auto-save like gmail but also via a button (like gmail).
  def update
    restrict('allow only store users') or begin
      status_changed = false
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      @data = @form.data
      if @data.update_attributes(params[params[:form_type]]) # & @form.instance.update
        @save_status = "Draft saved at " << Time.now.strftime("%I:%M %p").downcase + @data.save_status.to_s
logger.error "Status: #{@form.status} // #{params[:form_instance][:status]} -> #{params[:form_instance][:status].as_status.text}"
        if !params[:form_instance].nil? && !params[:form_instance][:status].blank? && !(params[:form_instance][:status] == @form.status.as_status.number)
logger.error "Again, Status: #{@form.status} // #{params[:form_instance][:status]} -> #{params[:form_instance][:status].as_status.text}"
          @form.status = params[:form_instance][:status].as_status.number
          if @form.save
logger.error "And yet again, Status: #{@form.status} // #{params[:form_instance][:status]} -> #{params[:form_instance][:status].as_status.text}"
            status_changed = true
          else
            flash[:notice] = "ERROR Submitting draft!"
          end
        end
      else
        @save_status = "ERROR auto-saving! (#{@data.errors.to_xml})"
      end
      respond_to do |format|
        format.html {
          flash[:error] = @data.errors.collect {|err| "#{err[0].humanize} #{err[1]}"}.join('</p><p class="error_message">')
          redirect_to status_changed ? store_dashboard_url() : store_forms_url(:form_type => @form.data_type, :form_id => @form.id)
        }
        format.js   {render :layout => false}
      end
    end
  end

  def view
    restrict('allow only store users') or begin
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      @data = @form.data
      @form_type = params[:form_type]
    end
  end

  def discard
    restrict('allow only store users') or begin
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      @status_count = current_user.forms_with_status(@form.status).count - 1
      @status_link_text_with_count = @form.status.as_status.word('uppercase short plural') + (@status_count == 0 ? '' : " (#{@status_count})")
      @status_container_fill = @status_count == 0 ? "<li>&lt;no current #{params[:form_status].as_status.word('lowercase short plural')}&gt;</li>" : nil
      @form.destroy
      respond_to do |format|
        format.html {}
        format.js   {render :layout => false}
      end
    end
  end

end
