class UsersController < ApplicationController
  in_place_edit_for :user, 'friendly_name'
  layout 'store'

  # render show.rhtml
  def show
    restrict('allow only store users') or begin
      @user = get_user
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @user.to_xml }
      end
    end
  end

  def update
    restrict('allow only store users') or begin
      @user = User.find_by_id(params[:id])
      respond_to do |format|
        params[:user] = {:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation], :operation => params[:user][:operation]} if params[:user][:operation] == 'changing_password' # Ensure ONLY password is being changed!
        params[:user].delete(:is_store_admin) unless current_user.is_store_admin? #Only store admins can make others an admin.
        if @user.update_attributes(params[:user])
          flash[:notice] = @user.operation == 'changing_password' ? "Your Password has been changed. Please remember your new password next time you log in." : "#{@user.friendly_name} has been updated."
          format.html { redirect_to current_user.is_store_admin? ? users_url : user_account_url }
          format.js
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.js
          format.xml  { render :xml => @user.errors.to_xml }
        end
      end
    end
  end


# 
# #This needs to be locked down to do only what it should be allowed to do
#   def update
#     restrict('allow only store users') or begin
#       @user = get_user
#       respond_to do |format|
#         if @user.update_attributes(params[:user])
#           format.html { redirect_to user_url(@user) }
#           format.js
#           format.xml  { head :ok }
#         else
#           format.html { render :action => "edit" }
#           format.js
#           format.xml  { render :xml => @user.errors.to_xml }
#         end
#       end
#     end
#   end

  # GET /users
  # GET /users.xml
  def index
    restrict('allow only store admins') or begin
      @users = User.find_all_by_store_id(Store.id_of_alias(params[:domain]))
      respond_to do |format|
        format.html # index.rhtml
        format.js
        format.xml  { render :xml => @users.to_xml }
      end
    end
  end

  # render new.rhtml
  def new
    restrict('allow only store admins') or begin
      @user = User.new
      @user.store_id = Store.id_of_alias(params[:domain])
    end
  end

# Need to create a search action in case user hits enter on the live_search box, or else disable hard-submit on the form.

  def live_search
    restrict('allow only store admins') or begin
      @phrase = (request.raw_post || request.query_string).slice(/[^=]+/)
      if @phrase.blank?
        render :nothing => true
      else
        @sqlphrase = "%" + @phrase.to_s + "%"
        @results = User.find(:all, :conditions => [ "friendly_name LIKE ? OR username LIKE ?", @sqlphrase, @sqlphrase])
        @search_entity = @results.length == 1 ? "User" : "Users"
        render(:partial => 'shared/live_search_results')
      end
    end
  end

  def create
    restrict('allow only store admins') or begin
      @user = User.new(params[:user])
      @user.store = Store.find_by_alias(params[:domain])
      if @user.save
        redirect_back_or_default(users_path)
        flash[:notice] = "User #{@user.friendly_name} has been created."
      else
        render :action => "new"
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
# THIS NEEDS TO USE THE ACTS_AS_DELETED PLUGIN!!
    restrict('allow only store admins') or begin
      @user = User.find_by_id(params[:id])
      @user.destroy
      respond_to do |format|
        format.html { redirect_to user_path() }
        format.xml  { head :ok }
      end
    end
  end

  private
    def get_user
      current_user.is_store_admin_or_admin? ? User.find_by_id(params[:id]) || current_user : current_user
    end
end
