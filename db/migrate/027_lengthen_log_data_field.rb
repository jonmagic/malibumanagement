class LengthenLogDataField < ActiveRecord::Migration
  def self.up
    change_column :logs, :data, :text
  end

  def self.down
    # There's really no discernable difference worth reverting...
    # change_column :logs, :data, :string
  end
end
