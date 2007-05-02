# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_malibu_session_id'
  include AuthenticatedSystem
  include RouteObjectMapping
  include AccessControl
  include CalendarReader
  before_filter :set_current_user
  before_filter :add_default_restrictions
  before_filter :go_to_where_you_belong
  layout 'default'

  def set_current_user
    Thread.current['user'] = current_user
  end

  def add_default_restrictions
    add_restriction('allow only store admins', current_user.is_store_admin? && current_user.store == accessed_store) {flash[:notice] = "Only Store Admins can access this. Please login with Store Admin credentials."; store_location; redirect_to store_login_path(accessed_domain)}
    add_restriction('allow only admins or store admins', current_user.is_store_admin_or_admin?) {flash[:notice] = "Only Store Admins can access this. Please login with Store Admin credentials."; store_location; redirect_to store_login_path(accessed_domain)}
    add_restriction('allow only store users', current_user.is_store_user? && current_user.store == accessed_store) {flash[:notice] = "Only Store Users can access this. Please login."; store_location; redirect_to store_login_path(accessed_domain)}
    add_restriction('allow only admins', current_user.is_admin?) {flash[:notice] = "Only Admins can access this. Please login."; store_location; redirect_to(admin_login_path)}
  end

#Virtually makes this publicly global for the app.
  def add_restriction(name, condition, &default_block)
    @ACL ||= AccessControlList.new
    @ACL.add_restriction(name, condition, default_block)
  end
  def restrict(name, &block)
    @ACL ||= AccessControlList.new
    logger.error "RESTRICTED" unless @ACL.restrictions[name][:condition]
    @ACL.restrict(name, block)
  end

  def paginate_by_sql(model, sql, per_page, options={})
    if options[:count]
      if options[:count].is_a? Integer
        total = options[:count]
      else
        total = model.count_by_sql(options[:count])
      end
    else
      total = model.count_by_sql_wrapping_select_query(sql)
    end
    object_pages = Paginator.new self, total, per_page, params[:page]
    objects = model.find_by_sql_with_limit(sql, object_pages.current.to_sql[1], per_page)
    return [object_pages, objects]
  end

  private
    # If logged in, teleport to own store, If not logged in, teleport to accessed_store's login page
    def go_to_where_you_belong
      
    end

end
