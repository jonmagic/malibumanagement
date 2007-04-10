class AddFileUploadToNotes < ActiveRecord::Migration
  def self.up
    add_column :notes, :attachment, :string
  end

  def self.down
    remove_column :notes, :attachment
  end
end
