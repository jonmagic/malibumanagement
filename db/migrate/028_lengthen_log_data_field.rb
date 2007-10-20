class LengthenLogDataField < ActiveRecord::Migration
  def self.up
    change_column :logs, :data, :text
  end

  def self.down
    change_column :logs, :data, :string
  end
end
