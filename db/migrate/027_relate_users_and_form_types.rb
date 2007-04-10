class RelateUsersAndFormTypes < ActiveRecord::Migration
  def self.up
    create_table :form_types_users, :id => false do |t|
      t.column :user_id,          :integer
      t.column :form_type_id,     :integer
    end
  end

  def self.down
    drop_table :form_types_users
  end
end
