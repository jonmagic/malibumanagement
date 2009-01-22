require File.dirname(__FILE__) + '/../test_helper'
require 'admins_stores_controller'

# Re-raise errors caught by the controller.
class AdminsStoresController; def rescue_action(e) raise e end; end

class AdminsStoresControllerTest < Test::Unit::TestCase
  def setup
    @controller = AdminsStoresController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
