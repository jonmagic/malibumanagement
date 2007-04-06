# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController  # layout 'store'

  # render new.rhtml
  def new
#Could check for a valid store (params[:domain]) and show an alternative login form (using email address) if not found.
    render :layout => 'default'
  end

  def create_admin
    logout if logged_in?
    user = Admin.valid_username?(params[:username])
    if !user.blank?
      self.current_user = Admin.authenticate(params[:username], params[:password])
      if logged_in?
logger.error "User: #{self.current_user.friendly_name} #{self.current_user.domain}"
        flash[:notice] = "Welcome " + self.current_user.friendly_name + "."
        redirect_back_or_default admin_dashboard_url
      else
        flash[:notice] = "Failed to log in."
        render :action => 'new_admin', :layout => 'admin'
      end
    else
      flash[:notice] = "Invalid username." if params[:username]
      render :action => 'new_admin', :layout => 'admin'
    end
  end

  def create_user
    logout if logged_in?
    user = User.valid_username?(params[:username])
    if !user.blank?
      self.current_user = User.authenticate(params[:username], params[:password], params[:domain])
      if logged_in?
        flash[:notice] = "Welcome " + self.current_user.friendly_name + "."
        redirect_back_or_default store_dashboard_url(self.current_user.store.alias)
      else
        flash[:notice] = "Failed to log in. If you have forgotten your password, please have the admin at your place reset your password for you."
        render :action => 'new_user', :layout => 'store'
      end
    else
      flash[:notice] = "Invalid username." if params[:username]
      render :action => 'new_user', :layout => 'store'
    end
  end

  def destroy
    if logged_in?
      dom = self.current_user.domain
logger.error "Domain: #{self.current_user.domain}"
      flash[:notice] = "You have been logged out."
       redirect_to dom == 'malibu' ? admin_login_url : store_login_url(dom)
    else
      redirect_to page_url
    end
  end
  private
    def logout
      cookies.delete :auth_token
      reset_session
    end
end