class Helios::ClientProfile < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'mysql',
    :database => 'HeliosBS',
    :host     => '127.0.0.1',
    :username => 'maly',
    :password => 'booboo'
  )

  set_table_name 'Client_Profile'
  set_primary_key 'Client_no'

  include HeliosPeripheral

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end
end
