class Manage::UsersController < ApplicationController
  layout 'admin'
  in_place_edit_for :user, 'friendly_name'

  def index
    restrict('allow only admins') or begin
      @store = Store.find_by_id(params[:store_id])
      @users = User.find_all_by_store_id(params[:store_id])
    end
  end

  def new
    restrict('allow only admins') or begin
      @store = Store.find_by_id(params[:store_id])
      @user = User.find_by_id(params[:id])
    end
  end

  def show
    restrict('allow only admins') or begin
      @store = Store.find_by_id(params[:store_id])
      @user = User.find_by_id(params[:id])
    end
  end

  def create
    restrict('allow only admins') or begin
      @user = User.new(params[:user])
      @user.store = Store.find_by_id(params[:store_id])
      if @user.save
        redirect_back_or_default(manage_users_url)
        flash[:notice] = "User #{@user.friendly_name} has been created."
      else
        render :action => "new"
      end
    end
  end

  def update
    restrict('allow only admins') or begin
      @user = User.find_by_id(params[:id])
      respond_to do |format|
        params[:user] = {:password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation], :operation => params[:user][:operation]} if params[:user][:operation] == 'changing_password' # Ensure ONLY password is being changed if changing_password - because other validations are turned off!
        if @user.update_attributes(params[:user])
          flash[:notice] = @user.operation == 'changing_password' ? "Your Password has been changed. Please remember your new password next time you log in." : "#{@user.friendly_name} has been updated."
          format.html { redirect_to manage_users_url }
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

#This would be better as rjs, with the typical fade out deletion.
  def destroy
    restrict('allow only admins') or begin
      @user = User.find_by_id(params[:id])
      return flash[:error] = "Cannot remove the last admin. Please delegate another to be admin before removing yourself." if @user.is_store_admin && @user.store.admins.length == 1
      if @user.destroy
        respond_to do |format|
          format.html { redirect_to manage_users_url }
          format.xml  { head :ok }
        end
      else
      
      end
    end
  end

end
