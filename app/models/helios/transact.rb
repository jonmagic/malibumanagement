class Helios::Transact < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'mysql',
    :database => 'HeliosBS',
    :host     => '127.0.0.1',
    :username => 'maly',
    :password => 'booboo'
  )

  set_table_name 'Transactions'
  set_primary_key 'transact_no'

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'
end
