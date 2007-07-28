class Helios::Inventory < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'mysql',
    :database => 'HeliosBS',
    :host     => '10.11.45.3',
    :username => 'maly',
    :password => 'booboo'
  )

  include HeliosPeripheral

  set_table_name 'inventory'
  set_unique_key 'inv_code'
end
