class Helios::Transact < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'mysql',
    :database => 'HeliosBS',
    :host     => '127.0.0.1',
    :username => 'maly',
    :password => 'booboo'
  )

  include HeliosPeripheral

  set_table_name 'Transactions'
  set_primary_key 'transact_no'
end
