class RelateStoresAndFormTypes < ActiveRecord::Migration
  def self.up
    create_table :stores_form_types, :id => false do |t|
      t.column :store_id,         :integer
      t.column :form_type_id,      :integer
    end
  end

  def self.down
    drop_table :stores_form_types
  end
end
