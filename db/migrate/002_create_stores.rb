class CreateStores < ActiveRecord::Migration
  def self.up
    create_table :stores do |t|
      t.column :alias,                     :string, :limit => 25
      t.column :friendly_name,             :string, :limit => 50
      t.column :address,                   :string
      t.column :contact_person,            :string, :limit => 25
      t.column :telephone,                 :string, :limit => 20
      t.column :tax_id,                    :string
      t.column :created_at,                :datetime
      t.column :updated_at,                :datetime
    end
  end

  def self.down
    drop_table :stores
  end
end
