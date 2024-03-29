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
        if current_user.is_store_admin?
          archive_view
        else
          history_view
        end
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
    restrict('allow only store admins') or begin
      render :action => 'archive_view'
    end
  end
  def history_view
    @result_pages, @results = paginate_by_sql(
      FormInstance,
      [
        "SELECT form_instances.* FROM form_instances WHERE (form_instances.user_id=:user_id OR form_instances.data_type='SalesReport') AND form_instances.store_id=:store_id AND form_instances.status_number=4 AND form_instances.created_at < :date ORDER BY form_instances.created_at DESC",
        {:date => Time.tomorrow, :store_id => current_store.id, :user_id => current_user.id}
      ],
      20
    )
logger.info "Search Results: #{@results.length} -- #{@results}"
    @search_entity = @results.length == 1 ? "Archived Form" : "Archived Forms"
    render :action => 'history_view'
  end

  def live_history
    @result_pages, @results = paginate_by_sql(
      FormInstance,
      [
        "SELECT form_instances.* FROM form_instances WHERE (form_instances.user_id=:user_id OR form_instances.data_type='SalesReport') AND form_instances.store_id=:store_id AND form_instances.status_number=4 AND form_instances.created_at < :date ORDER BY form_instances.created_at DESC",
        {:date => Time.tomorrow, :store_id => current_store.id, :user_id => current_user.id}
      ],
      20
    )
logger.info "Search Results: #{@results.length} -- #{@results}"
    @search_entity = @results.length == 1 ? "Archived Form" : "Archived Forms"
    render :partial => 'live_history', :layout => false
  end

#There should be three fields here: Store, Date
  def search(live=false)
    restrict('allow only store admins') or begin
      user    = nil
      date    = nil
      formtype = nil

      user    = "%" + params[:user_field]    + "%" if !params[:user_field].nil? and params[:user_field].length > 0
      formtype    = params[:formtype_field] if !params[:formtype_field].nil? and params[:formtype_field].length > 0
      date = (!params[:Time][:tomorrow].nil? and params[:Time][:tomorrow].length > 0) ? params[:Time][:tomorrow] : Time.tomorrow

      tables = ['form_instances']
      tables.push('users') unless user.nil?

      matches = ["form_instances.store_id=:store_id AND form_instances.status_number=4 AND form_instances.created_at < :date"] #Put the date field in first by default - there will always be a date to search for.
      matches.push('form_instances.data_type=:formtype') unless formtype.nil?
      matches.push('form_instances.user_id=users.id') unless user.nil?
      matches.push('users.friendly_name LIKE :user') unless user.nil?

      @form_values = {:Time => {:tomorrow => date}} #put the date field in first by default - there will always be a date to search for.
      @values = {:date => date, :store_id => current_store.id}
      @form_values.merge!({:user_field => params[:user_field]}) unless user.nil?
      @values.merge!({:user => user}) unless user.nil?
      @form_values.merge!({:formtype_field => params[:formtype_field]}) unless formtype.nil?
      @values.merge!({:formtype => formtype}) unless formtype.nil?

      @result_pages, @results = paginate_by_sql(FormInstance, ["SELECT form_instances.* FROM " + tables.join(',') + " WHERE " + matches.join(' AND ') + " ORDER BY form_instances.created_at DESC", @values], 20)
      @search_entity = @results.length == 1 ? "Archived Form" : "Archived Forms"
      render :layout => false
    end
  end
  def live_search
    search(true)
  end

#This is hit first. The form instance is created and then redirects to the editing ('draft') of the created form.
  def new
    restrict('allow only store users') or begin
      return redirect_to(store_dashboard_url) if params[:form_type] == 'chooser'
      @form = (!FormType.find_by_name(params[:form_type]).can_have_multiple_drafts && current_user.drafts_of_type(params[:form_type]).count > 0) ? current_user.drafts_of_type(params[:form_type])[0] : FormInstance.new(
        :user => current_user,
        :store => current_store,
        :form_type => current_form_model, #Automatically creates the connected form data via the appropriate (given) model
        :status => 'draft'
      )
      if !@form.id.nil? && !@form.data.id.nil?
        redirect_to store_forms_url(:form_status => 'draft', :form_type => @form.data_type, :action => 'draft', :form_id => @form.id)
      else
        raise RuntimeError, "Could not save the Form requested!"
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
      unless current_user.is_store_admin? || @form.user_id == current_user.id || @form.assigned_to == current_user.id || @form.data_type == 'SalesReport'
        flash[:notice] = "You don't have access to that form. Please select another."
        return redirect_to(store_dashboard_url)
      end
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
# This performs several functions (probably not good programming practice?!):
# 1) Only update assigned_to.
# 2) Only update status (submit).
# 3) Update attributes presented in form.
#
# The differences of input are as follows:
#   1) Assigned_to: form-attributes, form_instance => {:assigned_to => 1, :status => 'draft'}
#   2) Status: form-attributes, form_instance => {:status => 'submitted'}
#   3) Update Attributes: form-attributes, form_instance => {:status => 'draft'}
  def update
    restrict('allow only store users') or begin
      status_changed = false
      assigned_to_changed = false
      @save_status = ''
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      unless current_user.is_store_admin? || @form.user_id == current_user.id || @form.assigned_to == current_user.id || @form.data_type == 'SalesReport'
        flash[:notice] = "You don't have access to that form. Please select another."
        return redirect_to(store_dashboard_url)
      end

      if !params[:form_instance].nil?
        if (params[:form_instance].has_key?(:assigned_to) || params[:form_instance].has_key?('assigned_to')) && @form.assigned_to.to_s != params[:form_instance][:assigned_to].to_s
logger.info "Updating Assigned-to Only: #{@form.assigned_to.to_s} != #{params[:form_instance][:assigned_to].to_s}"
          assigned_to_changed = true
          @form.assigned = User.find_by_id(params[:form_instance][:assigned_to])
          params[:form_instance].delete(:status)
        elsif !params[:form_instance][:status].blank? &&
          params[:form_instance][:status].as_status.number != @form.status.as_status.number
logger.info "Updating Status Only: #{params[:form_instance][:status].as_status.number} != #{@form.status.as_status.number}"
          @form.status = params[:form_instance].delete(:status)
          status_changed = true
          params[:form_instance].delete(:assigned_to)
        end
      end

# THIS IS MESSY! (Just thought I'd let you know...)
      @data = @form.data
      if !assigned_to_changed && @form.data.update_attributes(params[params[:form_type]]) # & @form.update
        FormInstance.no_validate_data!
        if @form.update_attributes(params[:form_instance])
          @save_status = "Draft saved at " + Time.now.strftime("%I:%M %p").downcase + ' ' + @form.data.save_status.to_s
        else
logger.error "Error updating @form attributes?! (#{@form.errors.full_messages.to_sentence} / #{@form.data.errors.full_messages.to_sentence})"
          flash[:notice] = "ERROR Submitting draft!"
        end
      else
        FormInstance.no_validate_data!
        unless @form.update_attributes(params[:form_instance])
          @save_status << " ERROR auto-saving! (#{@form.errors.full_messages.to_sentence} / #{@form.data.errors.full_messages.to_sentence})"
        end
      end
      FormInstance.validate_data!
      if @form.data.respond_to?(:is_signed?) && !@form.data.is_signed?
        @form.status = 'draft'
        status_changed = false
        flash[:error] = 'This form must be signed before it can be submitted.'
      end
logger.info "Save Status: #{@save_status}"
      # @save_status << ' ' << @data.save_status.to_s

      respond_to do |format|
        if @form.errors.length > 0
logger.info "there were errors...?"
          flash[:error] = @form.data.errors.collect {|err| "#{err[0].humanize} #{err[1]}"}.join('</p><p class="error_message">')
          format.html do
            redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id)
          end
          format.js do
# Here we should insert the error messages, not reload the entire page.
            render :update do |page|
              page["draft_save_status"].replace_html(@form.errors.full_messages.to_sentence + ': ' + @form.data.errors.full_messages.to_sentence)
              # page.redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id)
            end
          end
        elsif params[:leave_page] == 'true'
          format.html { redirect_to store_dashboard_url }
          format.js do
            render :update do |page|
              page.redirect_to store_dashboard_url
            end
          end
        elsif params[:reload_page] == 'true'
logger.info "params[:reload_page] told us to reload"
          format.html { redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id) }
          format.js do
            render :update do |page|
              page.redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id)
            end
          end
        elsif @save_status =~ /signature accepted/i #Reloads the page automatically if it included a signature submit.
logger.info "Reloading page, then returning to dashboard in 5 seconds."
          format.html { redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id, :return_soon => 5) }
          format.js do
            render :update do |page|
              page.redirect_to store_forms_url(:form_type => @form.data_type, :form_id => @form.id) # Except for ajax -- we'd still need to submit the form.
            end
          end
        else
          format.html {
logger.info "Reloading by default (asked for html)..."
            flash[:error] = @form.data.errors.collect {|err| "#{err[0].humanize} #{err[1]}"}.join('</p><p class="error_message">')
            redirect_to status_changed ? store_dashboard_url() : store_forms_url(:form_type => @form.data_type, :form_id => @form.id)
          }
          format.js   {render :layout => false}
        end
      end
    end
  end

  def view
    restrict('allow only store users') or begin
      @form = FormInstance.find_by_id(params[:form_id])
      return redirect_to(store_dashboard_url) unless @form
      unless current_user.is_store_admin? || @form.user_id == current_user.id || @form.assigned_to == current_user.id || @form.data_type == 'SalesReport'
        flash[:notice] = "You don't have access to that form. Please select another."
        return redirect_to(store_dashboard_url)
      end
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
