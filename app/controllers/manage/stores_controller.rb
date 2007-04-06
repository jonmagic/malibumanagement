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

# Need to create a search action in case user hits enter on the live_search box, or else disable hard-submit on the form.
  def search(live = false)
    restrict('allow only admins') or begin
      @phrase = (request.raw_post || request.query_string).slice(/[^=]+/)
      if @phrase.blank?
        render :nothing => true
      else
        if @phrase == 'all'
          @results = Store.find(:all)
        else
          @sqlphrase = "%" + @phrase.to_s + "%"
          @results = Store.find(:all, :conditions => [ "friendly_name LIKE ? OR alias LIKE ? OR telephone LIKE ?", @sqlphrase, @sqlphrase, @sqlphrase])
        end
        @search_entity = @results.length == 1 ? "Store" : "Stores"
        logger.error "#{@results.length} results."
        render(:partial => 'shared/live_search_results') if live
      end
    end
  end

  def live_search
    search(true)
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
      @store = Store.new
      @user   = User.new
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
      @store = Store.new(params[:store])
      @user   = User.new(params[:user])
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
      @user   = @store.admin
      respond_to do |format|
  #This doesn't update the FormTypes association if all of them are unchecked...?
        if (@store.valid? & @user.valid?) &&  @store.update_attributes(params[:store]) && @user.update_attributes(params[:user])
          flash[:notice] = "Store was successfully updated."
          format.html { redirect_to store_url(@store) }
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
