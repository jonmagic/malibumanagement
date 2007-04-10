class RemoveAssocTablesForFormTypes < ActiveRecord::Migration
  def self.up
    drop_table :form_types_users
    add_column :users, :form_type_ids,      :string, :default => [].to_yaml #serialized
    drop_table :form_types_stores
    add_column :stores, :form_type_ids,     :string, :default => [].to_yaml #serialized
  end

  def self.down
    create_table :form_types_users, :id => false do |t|
      t.column :user_id,          :integer
      t.column :form_type_id,     :integer
    end
    remove_column :users, :form_type_ids
    create_table :form_types_stores, :id => false do |t|
      t.column :store_id,          :integer
      t.column :form_type_id,     :integer
    end
    remove_column :stores, :form_type_ids
  end
end
