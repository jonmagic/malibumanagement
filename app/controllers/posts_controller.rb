class PostsController < ApplicationController

    # GET /
    # GET /posts.xml
    def index
      @posts = Post.find(:all)
      respond_to do |format|
        format.html # index.rhtml
        format.xml  { render :xml => @posts.to_xml }
      end
    end

    def search(live=false)
      search    = nil

      search    = "%" + params[:search_field]    + "%" if !params[:search_field].nil? and params[:search_field].length > 0

      matches = ['created_at < :now'] #Put the before_date field in first by default - there will always be a date to search for.
      matches.push('(title LIKE :search OR text LIKE :search OR attachment LIKE :search)') unless search.nil?
      matches.push('0') if matches.blank? # This ensures a blank valid no-result search if there is absolutely nothing to search for.

      @values = {:now => Time.now}
      @post_values = {:dummy => 'value'}

      @values.merge!({:search => search}) unless search.nil?
      @post_values.merge!({:search_field => params[:search_field]}) unless search.nil?

      @result_pages, @results = paginate_by_sql(Post, ["SELECT * FROM posts WHERE " + matches.join(' AND ') + " ORDER BY created_at DESC", @values], 3)
      @search_entity = @results.length == 1 ? "Bulletin" : "Bulletins"
      render :layout => false
    end
    def live_search
      search(true)
    end

    # GET /posts/1
    # GET /posts/1.xml
    def show
      @post = Post.find_by_id(params[:id])
      respond_to do |format|
        format.html # show.rhtml
        format.xml  { render :xml => @post.to_xml }
      end
    end

    # GET /posts/new
    def new
      @post = Post.new
      respond_to do |format|
        format.html
        format.js {render :layout => false}
      end
    end

    # GET /posts/1;edit
    def edit
      @post = Post.find_by_id(params[:id])
      return render(:status => :ok) unless @post.author == current_user #Only allow the user who created the post to edit it.
      respond_to do |format|
        format.html
        format.js
      end
    end

    # POST /posts
    # POST /posts.xml
    def create
      @post = Post.new(params[:post])
      @post.author = current_user
      respond_to do |format|
        if @post.save
          format.html {redirect_to current_user.kind_of?(Admin) ? admin_posts_url : posts_url}
          format.js do
            responds_to_parent do
              render :update do |page|
                page.insert_html :top, 'posts_container', "<hr />"
                page.insert_html :top, 'posts_container', :partial => 'posts/show_post', :locals => { :post => @post }
                page['new_post_title'].value = ''
                page['new_post_text_area'].value = ''
                page['post_attachment_temp'].value = ''
                page['post_attachment'].value = ''
                page.hide('new_post_container')
              end # render
            end # responds_to_parent
          end # wants
          format.xml
        else
          format.html { render :action => "new" }
          format.js   {}
          format.xml 
        end
      end
    end

    # PUT /posts/1
    # PUT /posts/1.xml
    def update
      restrict('allow only admins and store users') or begin
        @post = Post.find_by_id(params[:id])
        @post.author = current_user
        respond_to do |format|
          if @post.update_attributes(params[:post])
            format.html 
            format.js   {}
            format.xml  { head :ok }
          else
            format.html { render :action => "edit" }
            format.js   {}
            format.xml  { render :xml => @post.errors.to_xml }
          end
        end
      end
    end

    # DELETE /posts/1
    # DELETE /posts/1.xml
    def destroy
      restrict('allow only admins and store users') or begin
        @post = Post.find_by_id(params[:id])
        @post.destroy
        respond_to do |format|
          format.html 
          format.js   {}
          format.xml  { head :ok }
        end
      end
    end

    def attachment
      restrict('allow only admins and store users') or begin
        @post = Post.find_by_id(params[:id])
        send_file @post.attachment, :type => Mime::Type.lookup_by_extension(@post.attachment).to_str, :disposition => 'inline'
      end
    end


end
