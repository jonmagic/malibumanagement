class Manage::AdminsController < ApplicationController
  in_place_edit_for :admin, 'friendly_name'
  layout 'admin'

  # GET /admins
  # GET /admins.xml
  def index
    restrict 'allow only admins' or begin
      @admins = Admin.find(:all)
      respond_to do |format|
        format.html # index.rhtml
        format.xml  { render :xml => @admins.to_xml }
      end
    end
  end

  # render new.rhtml
  def new
    restrict 'allow only admins'
  end

  def create
    restrict 'allow only admins' or begin
      @admin = Admin.new(params[:admin])
      if @admin.save
        redirect_back_or_default(admins_path)
        flash[:notice] = "Thanks for signing up!"
      else
        render :action => 'new'
      end
    end
  end

  # GET /stores/1
  # GET /stores/1.xml
  def show
    restrict 'allow only admins' or begin
      @admin = Admin.find_by_id(params[:id]) || current_user
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @admin.to_xml }
      end
    end
  end

  # GET /Malibu/dashboard
  def dashboard
    #To keep someone from getting a page that doesn't map to a real store, anonymous will be expelled from this action to the login page, and anyone logged in will be redirected to their respective store
    restrict 'allow only admins'
  end

  def update
    restrict('allow only admins') or begin
      @admin = Admin.find_by_id(params[:id])
      respond_to do |format|
# It is possible to fool the system slightly by sending param 'admin[operation]=changing_password' to bypass validation of username and email. I'll assume nobody will ever have a malicious need to do that.
        if @admin.update_attributes(params[:admin])
          flash[:notice] = @admin.operation == 'changing_password' ? "Your Password has been changed. Please remember your new password next time you log in." : "#{@admin.friendly_name} has been updated."
          format.html { redirect_to admin_url(@admin) }
          format.js
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.js
          format.xml  { render :xml => @admin.errors.to_xml }
        end
      end
    end
  end

  # DELETE /admins/1
  # DELETE /admins/1.xml
  def destroy
    restrict 'allow only admins' or begin
      @admin = Admin.find_by_id(params[:id])
      @admin.destroy
      respond_to do |format|
        format.html { redirect_to admins_url }
        format.xml  { head :ok }
      end
    end
  end

end
