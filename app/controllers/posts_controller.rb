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
          format.html
          format.js do
            responds_to_parent do
              render :update do |page|
                page.insert_html :bottom, 'posts_container', :partial => 'posts/show_post', :locals => { :post => @post }
                page['new_post_title_field'].value = ''
                page['new_post_text_area'].value = ''
                page['post_attachment_temp'].value = ''
                page['post_attachment'].value = ''
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
      restrict('allow only store users') or begin
        @post = Post.find_by_id(params[:id])
        @post.form_instance = current_form_instance
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
      restrict('allow only store users') or begin
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
      restrict('allow only store users') or begin
        @post = Post.find_by_id(params[:id])
        send_file @post.attachment, :type => Mime::Type.lookup_by_extension(@post.attachment).to_str, :disposition => 'inline'
      end
    end


end
