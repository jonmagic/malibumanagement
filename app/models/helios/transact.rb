class Helios::Transact < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'sqlserver',
    :database => 'HeliosBS',
    :host     => '.',
    :username => 'OpenHelios',
    :password => 'adshf98a4yaw'
  )

  set_table_name 'Transactions'
  set_primary_key 'transact_no'

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'
end
