require File.dirname(__FILE__) + '/../test_helper'
require 'stores_controller'

# Re-raise errors caught by the controller.
class StoresController; def rescue_action(e) raise e end; end

class StoresControllerTest < Test::Unit::TestCase
  fixtures :stores
  fixtures :users

  def setup
    @controller = StoresController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

#Create
# requires alias
# requires friendly_name
# requires address
# requires telephone
# requires user[friendly_name]
# requires user[email]

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:stores)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end
  
  def test_should_create_store
    old_count = Store.count
    post :create, :store => { :alias => 'gramit', :friendly_name => "Gramit", :address => "278 Art Buelevard", :telephone => "7681234567" }, :user => { :email => "test@exampl.com", :friendly_name => "Thomas Aquinas" }

    assert_equal old_count+1, Store.count
    
    assert_redirected_to store_path(assigns(:store))
  end

  def test_should_show_store
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end
  
  def test_should_update_store
    put :update, :id => 1, :store => { }
    assert_redirected_to store_path(assigns(:store))
  end
  
  def test_should_destroy_store
    old_count = Store.count
    delete :destroy, :id => 1
    assert_equal old_count-1, Store.count
    
    assert_redirected_to stores_path
  end
end
