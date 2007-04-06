class Manage::UsersController < ApplicationController
  layout 'admin'
  in_place_edit_for :user, 'friendly_name'
  in_place_edit_for :user, 'email'

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
      @user = User.new
      @user.friendly_name = params[:user][:friendly_name]
      @user.email = params[:user][:email]
      @user.store = Store.find_by_id(params[:store_id])
      if @user.save
        redirect_back_or_default(manage_users_url)
        flash[:notice] = "User #{@user.friendly_name} has been created."
      else
        render :action => "new"
      end
    end
  end

  def unactivate
    restrict('allow only admins') or begin
      @user = User.find_by_id(params[:id])
      respond_to do |format|
        if @user.unactivate
          format.html { redirect_to manage_users_url }
        else
logger.error "Could not reset password! #{@user.errors.to_yaml}\n"
          flash[:notice] = "Could not reset password for #{@user.friendly_name}!"
          format.html { redirect_to manage_users_url }
        end
      end
    end
  end

#This would be better as rjs, with the typical fade out deletion.
  def destroy
    restrict('allow only admins') or begin
      @user = User.find_by_id(params[:id])
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
