class AddSatelliteStatusTable < ActiveRecord::Migration
  def self.up
    create_table :satellite_statuses, :force => true do |t|
      t.column :session_key, :string
      t.column :status_text, :string
      t.column :percent, :integer
    end
  end

  def self.down
    drop_table :satellite_statuses
  end
end
