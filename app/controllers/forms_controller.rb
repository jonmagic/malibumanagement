class FormsController < ApplicationController
  layout 'store'
  before_filter :add_form_restrictions

  def add_form_restrictions
    add_restriction('allow only if valid form type', !current_store.form_model(params[:form_type]).nil?) {
      flash[:notice] = "Attempted access of unauthorized form type!"
    } if logged_in? and current_user.is_store_user?
  end

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

  #There should be three fields here: Store, Customer, Date
    def search(live=false)
      user    = nil
      customer = nil
      date    = nil

      user    = "%" + params[:user_field]    + "%" if !params[:user_field].nil? and params[:user_field].length > 0
      customer = "%" + params[:customer_field] + "%" if !params[:customer_field].nil? and params[:customer_field].length > 0
      date = (!params[:Time][:tomorrow].nil? and params[:Time][:tomorrow].length > 0) ? params[:Time][:tomorrow] : Time.tomorrow
  #Learn how to handle Dates in rails' forms
      # date    = params[:date_field].nil? ? Date.new. : params[:date_field]

  # logger.error "D: #{store}/#{params[:store_field]}; U: #{user}/#{params[:user_field]}; P: #{customer}/#{params[:customer_field]}; T: #{date}/#{params[:Time][:now]}\n"

      tables = ['form_instances']
      tables.push('users') unless user.nil?
      tables.push('customers') unless customer.nil?

      matches = ["form_instances.store_id=:store_id AND form_instances.status_number=4 AND form_instances.created_at < :date"] #Put the date field in first by default - there will always be a date to search for.
      matches.push('form_instances.user_id=users.id') unless user.nil?
      matches.push('form_instances.customer_id=customers.id') unless customer.nil?
      matches.push('users.friendly_name LIKE :user') unless user.nil?
      matches.push('(customers.first_name LIKE :customer OR customers.last_name LIKE :customer OR customers.account_number LIKE :customer OR customers.address LIKE :customer)') unless customer.nil?

      @form_values = {:Time => {:tomorrow => date}} #put the date field in first by default - there will always be a date to search for.
      @values = {:date => date, :store_id => current_store.id}
      @form_values.merge!({:user_field => params[:user_field]}) unless user.nil?
      @values.merge!({:user => user}) unless user.nil?
      @form_values.merge!({:customer_field => params[:customer_field]}) unless customer.nil?
      @values.merge!({:customer => customer}) unless customer.nil?

  # SELECT form_instances.* FROM form_instances,stores,users,customers WHERE form_instances.store_id=stores.id AND form_instances.user_id=users.id AND form_instances.customer_id=customers.id AND stores.friendly_name LIKE :store AND users.friendly_name LIKE :user AND (customers.first_name LIKE :customer OR customers.last_name LIKE :customer OR customers.account_number LIKE :customer OR customers.address LIKE :customer)

      @result_pages, @results = paginate_by_sql(FormInstance, ["SELECT form_instances.* FROM " + tables.join(',') + " WHERE " + matches.join(' AND ') + " ORDER BY form_instances.created_at DESC", @values], 30, options={})
      @search_entity = @results.length == 1 ? "Archived Form" : "Archived Forms"
      render :layout => false
    end
    def live_search
      search(true)
    end

#This is hit first, with an existing OR new customer. The form instance is created and then redirects to the editing ('draft') of the created form.
  def new
    restrict('allow only store users') or begin
      return redirect_to(store_dashboard_url) if params[:form_type] == 'chooser'
      @customer = Customer.find_by_id(params[:customer_id]) || Customer.create(:store => current_store)
      return redirect_to store_dashboard_path() unless @customer.store_id == current_user.store_id
      @form_instance = FormInstance.new(
        :user => current_user,
        :store => current_store,
        :customer => @customer,
        :form_type => current_form_model, #Automatically creates the connected form data via the appropriate (given) model
        :status => 'draft'
      )

      if @form_instance.form_data.update_attributes(@customer.attributes)
        # @form.instance = FormInstance.new(
        #                         :user_id => current_user.id,
        #                         :store_id => current_store.id,
        #                         :customer_id => @customer.id,
        #                         :form_type => FormType.find_by_form_type(params[:form_type]),
        #                         :form_type_id => FormType.find_by_form_type(params[:form_type]).id,
        #                         :status => 'draft')
        if @form_instance.save
          redirect_to store_forms_url(:form_status => 'draft', :form_type => @form_instance.form_data_type, :action => 'draft', :form_id => @form_instance.form_data_id)
        else
          render :action => 'draft'
        end
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
      @form = FormType.model_for(@form_type).find_by_id(params[:form_id])
      # Drop the status down to draft!
      if !(@form.instance.status == 'draft')
        @form.instance.status = 'draft'
        @form.instance.save
      end
      @customer = @form.instance.customer
      @values = @form
    end
  end

#This is for submitting edits. This is an ajax-specific function, normally auto-save like gmail but also via a button (like gmail).
  def update
    restrict('allow only store users') or begin
      status_changed = false
      @form = FormType.model_for(params[:form_type]).find_by_id(params[:form_id])
      if @form.instance.customer.update_attributes(params[params[:form_type]]) & @form.update_attributes(params[params[:form_type]]) # & @form.instance.update
        @save_status = "Draft saved at " << Time.now.strftime("%I:%M %p").downcase
        if !params[:form_instance].nil? && !params[:form_instance][:status].blank? && !(params[:form_instance][:status] == @form.instance.status)
          @form.instance.status = params[:form_instance][:status]
          if @form.instance.save
            # Log.create(:log_type => 'status:update', :data => {})
            status_changed = true
          else
            flash[:notice] = "ERROR Submitting draft!"
          end
        end
      else
        @save_status = "ERROR auto-saving!"
      end
      respond_to do |format|
        format.html {redirect_to status_changed ? store_forms_by_status_url(:form_status => @form.instance.status) : store_forms_url(:form_type => @form.instance.form_data_type, :form_id => @form.instance.form_data_id)}
        format.js   {render :layout => false}
      end
    end
  end

  def view
    restrict('allow only store users') or begin
      @form_type = params[:form_type]
      @form = FormType.model_for(@form_type).find_by_id(params[:form_id])
    end
  end

  def discard
    restrict('allow only store users') or begin
      @form = FormInstance.find_by_form_data_type_and_form_data_id(params[:form_type], params[:form_id])
      @status_count = current_user.forms_with_status(@form.status).count - 1
      @status_link_text_with_count = @form.status.as_status.word('uppercase short plural') + (@status_count == 0 ? '' : " (#{@status_count})")
      @status_container_fill = @status_count == 0 ? "<li>&lt;no current #{params[:form_status].as_status.word('lowercase short plural')}&gt;</li>" : nil
      customer = @form.customer
      @form.destroy
      #Also destroy customer if this is the only existing form for that customer and the customer has only a few values recorded and customer was created in the past 18 hours.
      customer.destroy if customer.form_instances(true).count == 0 and !customer.has_essentials? and customer.created_at > 18.hours.ago
      #****
      respond_to do |format|
        format.html {}
        format.js   {render :layout => false}
      end
    end
  end

end
