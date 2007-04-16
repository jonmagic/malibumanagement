class CreateFormInstances < ActiveRecord::Migration
  def self.up
    create_table "form_instances",    :force => true do |t|
      t.column "form_type_id",        :integer
      t.column "store_id",            :integer
      t.column "customer_id",         :integer
      t.column "user_id",             :integer
      t.column "data_id",             :integer
      t.column "data_type",           :string
      t.column "status_number",       :integer,  :default => 1
      t.column "created_at",          :datetime
      t.column "submitted",           :boolean
      t.column "has_been_submitted",  :boolean,  :default => false
    end
  end

  def self.down
    drop_table :form_instances
  end
end
