ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

#/sessions/[new,create,destroy]
#  map.resources :sessions
  map.connect '/', :controller => 'stores', :action => 'redir_from_root'

#/pages/[show, etc]
  map.page '/pages/:stub', :controller => 'pages', :action => 'show', :stub => 'index'

#/logout
  map.connect '/logout', :controller => 'sessions', :action => 'destroy'

#/mydoc/login OR /manage/login
  map.admin_login '/malibu/login', :controller => 'sessions', :action => 'create_admin'

# * * * * * * * *

# * * * * * * * * * * * * * * * * * * * * * * * *

#* * * * * * *
# A D M I N S *
#* * * * * * *

  if APP_CONFIG[:FEATURES].include?(:forms)
    map.admin_dashboard                 '/malibu',        :controller => 'manage/forms',   :action => 'index'
  elsif APP_CONFIG[:FEATURES].include?(:master_inventory)
    map.admin_dashboard                 '/malibu',        :controller => 'master_inventory_report',   :action => 'index'
  elsif APP_CONFIG[:FEATURES].include?(:open_helios)
    map.admin_dashboard                 '/malibu',        :controller => 'helios',   :action => 'index'
  elsif APP_CONFIG[:FEATURES].include?(:work_schedules)
    map.admin_dashboard                 '/malibu',        :controller => 'manage/stores',   :action => 'work_schedule'
  elsif APP_CONFIG[:FEATURES].include?(:bulletin_board)
    map.admin_dashboard                 '/malibu',        :controller => 'stores',   :action => 'bulletin_board'
  end
  map.admin_schedule '/malibu/work_schedule/:store_alias', :controller => 'manage/stores', :action => 'work_schedule'
  map.admin_bulletin '/malibu/bulletin_board', :controller => 'stores', :action => 'bulletin_board'
  map.resources :posts, :name_prefix => 'admin_', :path_prefix => '/malibu/bulletin_board', :collection => { :live_search => :any, :search => :any }, :member => {:attachment => :get}
  map.resources :master_inventory_price_list_items, :path_prefix => '/malibu'
  map.resources :master_inventory_report, :path_prefix => '/malibu' do |report|
    report.resources :master_inventory_price_list_items
  end
  map.resources :helios_clients, :path_prefix => '/malibu/helios', :collection => {:live_search => :any, :search => :any}, :member => { :exists => :any }
  map.resources :client_members, :path_prefix => '/malibu/helios', :collection => {:live_search => :any, :search => :any}, :member => { :remove_vip => :any, :reload_eft => :any }

  map.open_helios '/malibu/helios/:action/:id', :controller => 'helios', :action => 'index'
  map.helios '/malibu/helios/:action', :controller => 'helios', :action => 'index', :format => 'html'
  map.formatted_helios '/malibu/helios/:action.:format', :controller => 'helios', :action => 'index', :format => 'xml'
  map.eft           '/malibu/eft/:action',        :controller => 'eft', :action => 'admin_eft', :format => 'html'
  map.formatted_eft '/malibu/eft/:action.:format',:controller => 'eft', :action => 'admin_eft', :format => 'xml'

  map.resources :admins,     :path_prefix => '/malibu/manage', :controller => 'manage/admins',  :collection => { :live_search => :any, :search => :any, :set_admin_friendly_name => :any }, :member => { :update => :update }
  map.resources :stores,    :path_prefix => '/malibu/manage', :controller => 'manage/stores' do |store|
    store.resources :users, :name_prefix => 'manage_',          :controller => 'manage/users',   :collection => { :live_search => :any, :search => :any, :set_user_friendly_name => :any }, :member => { :update => :update }
  end
  map.resources :pages, :path_prefix => '/malibu/manage',   :controller => 'manage/pages', :name_prefix => 'manage_'
  map.admin_account   '/malibu/manage/myaccount/:action',   :controller => 'manage/admins', :action => 'show'

  map.admin_search_forms    '/malibu/forms/search', :controller => 'manage/forms', :action => 'search'
  map.admin_live_search_forms    '/malibu/forms/live_search', :controller => 'manage/forms', :action => 'live_search'
  map.admin_forms_by_status '/malibu/forms/:form_status/:action',                             :controller => 'manage/forms', :action => 'index', :form_status => nil
  map.resources :notes, :path_prefix => '/malibu/forms/:form_status/:form_type/:form_id',     :controller => 'manage/notes', :name_prefix => 'admin_', :member => { :attachment => :get }
  map.admin_form_log '/malibu/forms/:form_type/:form_id/logs', :controller => 'manage/logs', :action => 'form_logs'
  map.formatted_admin_forms '/malibu/forms/:form_status/:action/:form_type/:form_id.:format', :controller => 'manage/forms', :action => 'view',   :format => 'html'
  map.admin_forms           '/malibu/forms/:form_status/:form_type/:form_id/:action',         :controller => 'manage/forms', :action => 'view'

# * * * * * * * * * * * * * * * * * * * * * * * *

#* * * * * * *
# S T O R E S *
#* * * * * * *

  if APP_CONFIG[:FEATURES].include?(:forms)
    map.store_dashboard                        '/stores/:domain',        :controller => 'stores',   :action => 'dashboard'
  elsif APP_CONFIG[:FEATURES].include?(:work_schedules)
    map.store_dashboard                        '/stores/:domain',        :controller => 'stores',   :action => 'work_schedule'
  elsif APP_CONFIG[:FEATURES].include?(:bulletin_board)
    map.store_dashboard                        '/stores/:domain',        :controller => 'stores',   :action => 'bulletin_board'
  elsif APP_CONFIG[:FEATURES].include?(:eft)
    map.store_dashboard                        '/stores/:domain',        :controller => 'store_eft',   :action => 'managers_eft', :format => 'html'
  end
  map.store_dashboard '/stores/:domain', :controller => 'stores', :action => 'dashboard'
  map.store_schedule '/stores/:domain/work_schedule', :controller => 'stores', :action => 'work_schedule'
  map.bulletin_board '/stores/:domain/bulletin_board', :controller => 'stores', :action => 'bulletin_board'
  map.resources :posts, :path_prefix => '/stores/:domain', :collection => { :live_search => :any, :search => :any }, :member => {:attachment => :get}
  map.store_login '/stores/:domain/login', :controller => 'sessions', :action => 'create_user'
  map.store_profile '/stores/:domain/manage/profile/:action', :controller => 'stores', :action => 'profile'

  map.resources :users, :path_prefix => '/stores/:domain/manage', :collection => { :live_search => :any, :search => :any }, :member => { :update => :update }
  map.user_account '/stores/:domain/myaccount/:action', :controller => 'users', :action => 'show'

  map.store_eft           '/stores/:domain/eft/:action',        :controller => 'store_eft', :action => 'managers_eft', :format => 'html'
  map.formatted_store_eft '/stores/:domain/eft/:action.:format',:controller => 'store_eft', :action => 'managers_eft', :format => 'xml'

  map.store_search_forms      '/stores/:domain/forms/search',      :controller => 'forms', :action => 'search'
  map.store_live_search_forms '/stores/:domain/forms/live_search', :controller => 'forms', :action => 'live_search'
  map.store_forms_history '/stores/:domain/forms/history', :controller => 'forms', :action => 'live_history'
  map.store_forms_by_status '/stores/:domain/forms/:form_status/:action',                     :controller => 'forms',       :action => 'index', :form_status => nil
  map.resources :notes, :path_prefix => '/stores/:domain/forms/:form_status/:form_type/:form_id', :name_prefix => 'store_', :member => {:attachment => :get}
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
