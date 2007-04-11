module RouteObjectMapping

  class ActionController::Base
    def default_url_options(options)
      {:domain => accessed_domain} unless accessed_domain == 'malibu'
    end
  end

    def accessed_domain
      @accessed_domain ||= (params[:domain] || 'malibu')
    end
    def accessed_store
      @accessed_store ||= accessed_domain == 'malibu' ? Store.new(:friendly_name => 'Malibu', :alias => 'malibu') : Store.find_by_alias(accessed_domain)
    end
    def current_domain
      #Is this always what I want to return here?
      @current_domain ||= logged_in? ? current_user.domain : session[:domain]
    end
    def current_store
      @current_store ||= logged_in? ? current_user.store : nil
    end

#These are VERY useful!
    def current_form_model
      @current_form_model ||= Store.form_model(params[:form_type])
    end
    def current_form_instance
      @current_form ||= FormInstance.find_by_id(params[:form_id])
    end
    def current_form
      @current_form_instance ||= current_form_instance.nil? ? nil : current_form_instance.form_data
    end
    def given_activation_code
      @given_activation_code ||= params[:user] ? (params[:user][:activation_code] || params[:activation_code]) : (params[:admin] ? (params[:admin][:activation_code] || params[:activation_code]) : params[:activation_code])
    end

    # Inclusion hook to make some methods available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :accessed_domain, :accessed_store, :current_domain, :current_store, :current_form_model, :current_form_instance, :current_form, :given_activation_code
    end

# #Validate for ACCESS
#     def validate_store_and_form_type
#      #Keep people out of stores that are not their own or do not exist
#       redirect_if_invalid_store_alias(current_domain)
#      #Keep people away from form types that don't belong to their store or do not exist
#       redirect_if_invalid_form_type if !params[:form_type].blank?
#     end
#     def require_admin_except_for_show
#       redirect_if_invalid_store_alias('malibu') unless params[:action] == 'show'
#     end
# 
#     def redirect_if_invalid_store_alias(domain)
#       if logged_in?
#         if !(current_user.domain == domain)
#           store_location
#           redirect_to_url(store_dashboard_path(current_domain))
#         end
#       else
#         if domain == "malibu" or Store.exists?(domain)
#           store_location
#           redirect_to_url(login_url(domain))
#         else
#           redirect_back_or_default('/')
#         end
#       end
#     end
#     
#     def redirect_if_invalid_form_type
#       redirect_back_or_default(form_type_chooser_url) if !current_form_model and current_store.form_ids.include?(find_by_form_type(form_type).id)
#     end
end
