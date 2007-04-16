class Manage::StoresController < ApplicationController
  layout 'admin'

  # GET /stores
  # GET /stores.xml
  def index
    restrict('allow only admins') or begin
      @stores = Store.find(:all)
      respond_to do |format|
        format.html # index.rhtml
        format.xml  { render :xml => @stores.to_xml }
      end
    end
  end

  # GET /stores/1
  # GET /stores/1.xml
  def show
    restrict('allow only admins') or begin
      @store = Store.find_by_id(params[:id])
      @user   = @store.admin
      respond_to do |format|
        format.html # show.rhtml
        # format.xml  { render :xml => (:store_account => {:store => @store, :user => @user}).to_xml }
      end
    end
  end

  # GET /stores/new
  def new
    restrict('allow only admins') or begin
      @user   = User.new(:form_type_ids => [FormType.find_by_name('ManagerReport').id, FormType.find_by_name('NoticeOfTermination').id, FormType.find_by_name('PerformanceReview').id, FormType.find_by_name('VerbalWarning').id, FormType.find_by_name('WrittenWarning').id, FormType.find_by_name('IncidentReport').id])
      @store  = Store.new(:form_type_ids => [FormType.find_by_name('SalesReport').id, FormType.find_by_name('HandbookAcknowledgement').id], :admin => @user)
      @user.store = @store
    end
  end

  # GET /stores/1;edit
  def edit
    restrict('allow only admins') or begin
      @store = Store.find_by_id(params[:id])
      @user   = @store.admin
    end
  end

  # POST /stores
  # POST /stores.xml
  def create
#This really doesn't go here but there might be a need for it to be set?
#  default_url_options(:host => 'localhost:3000')
    restrict('allow only admins') or begin
      @user   = User.new(params[:user])
      @store  = Store.new(params[:store].merge({:admin => @user}))
      @user.username = @store.alias
      @user.store_id = 1 #Fake the validation, this will be overwritten as soon as the store is created.
      respond_to do |format|
        if @store.valid? & @user.valid?
          @store.save
          @user.store_id = @store.id
          @user.save
  #        flash[:notice] = "Store [#{@store.friendly_name} @ #{@store.alias} (#{@store.id})] was successfully created, with user [#{@user.friendly_name} @ #{@user.username}]."
          format.html { redirect_to store_url(@store) }
          format.xml  { head :created, :location => store_url(@store) }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @store.errors.to_xml }
        end
      end
    end
  end

#This needs to be locked down to do only what it should be allowed to do
  # PUT /stores/1
  # PUT /stores/1.xml
  def update
    restrict('allow only admins') or begin
      @store = Store.find(params[:id])
      respond_to do |format|
  #This doesn't update the FormTypes association if all of them are unchecked...?
        if @store.valid? && @store.update_attributes(params[:store])
          flash[:notice] = "Store was successfully updated."
          format.html { redirect_to stores_url }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @store.errors.to_xml }
        end
      end
    end
  end

  def dashboard
    restrict('allow only admins')
  end

  # DELETE /stores/1
  # DELETE /stores/1.xml
  def destroy
#Use the acts_as_deleted plugin!!!
#****
    restrict('allow only admins') or begin
      @store = Store.find(params[:id])
      @store.destroy
      respond_to do |format|
        format.html { redirect_to stores_url }
        format.xml  { head :ok }
      end
    end
  end

end
