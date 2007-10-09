class Helios::Eft < ActiveRecord::Base
  case ::RAILS_ENV
  when 'development'
    self.establish_connection(
      :adapter  => 'mysql',
      :database => 'HeliosBS',
      :host     => 'localhost',
      :username => 'maly',
      :password => 'booboo'
    )
  when 'production'
    self.establish_connection(
      :adapter  => 'sqlserver',
      :mode => 'ODBC',
      :dsn => 'HeliosBS'
    )
  end

  set_table_name 'EFT'
  set_primary_key 'Client_No'

  has_one :client_profile, :class_name => 'Helios::ClientProfile', :foreign_key => 'Client_No'
  
  include HeliosPeripheral

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end
end
