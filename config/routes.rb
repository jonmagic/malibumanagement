ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

#/sessions/[new,create,destroy]
#  map.resources :sessions

#/pages/[show, etc]
  map.page '/pages/:stub', :controller => 'pages', :action => 'show', :stub => 'index'

#/logout
  map.connect '/logout', :controller => 'sessions', :action => 'destroy'

#/mydoc/login OR /manage/login
  map.admin_login '/malibu/login', :controller => 'sessions', :action => 'create_admin'

# * * * * * * * *

  map.test '/test/:action/:id', :controller => 'manage/test', :action => 'dashboard'

# * * * * * * * * * * * * * * * * * * * * * * * *

#* * * * * * *
# A D M I N S *
#* * * * * * *

  map.admin_dashboard                        '/malibu',        :controller => 'manage/forms',   :action => 'index'
  map.resources :admins,     :path_prefix => '/malibu/manage', :controller => 'manage/admins',  :collection => { :register => :any, :activate => :any, :unactivate => :any, :live_search => :any, :search => :any, :set_user_friendly_name => :any, :set_user_email => :any }
  map.resources :stores,    :path_prefix => '/malibu/manage', :controller => 'manage/stores', :collection => { :live_search => :any, :search => :any } do |store|
    store.resources :users, :name_prefix => 'manage_',          :controller => 'manage/users',   :collection => { :live_search => :any, :search => :any, :set_user_friendly_name => :any, :set_user_email => :any }, :member => { :unactivate => :any }
  end
  map.resources :pages, :path_prefix => '/malibu/manage',   :controller => 'manage/pages', :name_prefix => 'manage_'
  map.admin_account   '/malibu/manage/myaccount/:action',   :controller => 'manage/admins', :action => 'show'

  map.admin_search_forms    '/malibu/forms/search', :controller => 'manage/forms', :action => 'search'
  map.admin_live_search_forms    '/malibu/forms/live_search', :controller => 'manage/forms', :action => 'live_search'
  map.admin_forms_by_status '/malibu/forms/:form_status/:action',                             :controller => 'manage/forms', :action => 'index', :form_status => nil
  map.resources :notes, :path_prefix => '/malibu/forms/:form_status/:form_type/:form_id',     :controller => 'manage/notes', :name_prefix => 'admin_'
  map.admin_form_log '/malibu/forms/:form_type/:form_id/logs', :controller => 'manage/logs', :action => 'form_logs'
  map.formatted_admin_forms '/malibu/forms/:form_status/:action/:form_type/:form_id.:format', :controller => 'manage/forms', :action => 'view',   :format => 'html'
  map.admin_forms           '/malibu/forms/:form_status/:form_type/:form_id/:action',         :controller => 'manage/forms', :action => 'view'

# * * * * * * * * * * * * * * * * * * * * * * * *

#* * * * * * * *
# D O C T O R S *
#* * * * * * * *

  map.store_dashboard '/stores/:domain', :controller => 'stores', :action => 'dashboard'
  map.store_login '/stores/:domain/login', :controller => 'sessions', :action => 'create_user'
  map.store_profile '/stores/:domain/manage/profile/:action', :controller => 'stores', :action => 'profile'

  map.resources :users, :path_prefix => '/stores/:domain/manage', :collection => { :register => :any, :activate => :any, :live_search => :any, :search => :any }, :member => { :unactivate => :any }
  map.user_account '/stores/:domain/myaccount/:action', :controller => 'users', :action => 'show'

  map.store_search_forms      '/stores/:domain/forms/search',      :controller => 'forms', :action => 'search'
  map.store_live_search_forms '/stores/:domain/forms/live_search', :controller => 'forms', :action => 'live_search'
  map.store_forms_by_status '/stores/:domain/forms/:form_status/:action',                     :controller => 'forms',       :action => 'index', :form_status => nil
  map.resources :notes, :path_prefix => '/stores/:domain/forms/:form_status/:form_type/:form_id', :name_prefix => 'store_'
  map.store_form_log '/stores/:domain/forms/:form_type/:form_id/logs', :controller => 'logs', :action => 'form_logs'
  map.formatted_store_forms '/stores/:domain/forms/:form_status/:form_type/:form_id/:action.:format', :controller => 'forms', :action => 'new', :format => 'html'
  map.store_draft '/stores/:domain/forms/draft/:form_type/new', :controller => 'forms', :action => 'new', :form_status => 'draft'
  map.store_forms '/stores/:domain/forms/:form_status/:form_type/:form_id/:action', :controller => 'forms', :action => 'draft'

# * * * * * * * * * * * * * * * * * * * * * * * *

  map.logs '/manage/logs/:action', :controller => 'logs', :action => 'history'

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
#  map.connect ':controller/service.wsdl', :action => 'wsdl'

  # Install the default route as the lowest priority.
#  map.connect ':controller/:action/:id.:format'
#  map.connect ':controller/:action/:id'
end
