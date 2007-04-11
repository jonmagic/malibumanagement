class CreateBaseEnvironment < ActiveRecord::Migration
  def self.up
    create_table "admins", :force => true do |t|
      t.column "username",         :string
      t.column "friendly_name",    :string,   :limit => 50
      t.column "crypted_password", :string,   :limit => 40
      t.column "salt",             :string,   :limit => 40
      t.column "created_at",       :datetime
      t.column "updated_at",       :datetime
      t.column "activated_at",     :datetime
    end
    #Creates a user/pass:  admin/admin, to allow for a login upon app creation.
        execute 'INSERT INTO admins(username, friendly_name, crypted_password, salt, created_at, activated_at) VALUES("admin", "Administrator", "0b73f51fe263f2053c223015a8ed678a2d39111b", "1b441d02f043b07276e4f09a8d084254bef8350e", "' + Time.now.to_s + '", "' + Time.now.to_s + '")'
    # ****

    create_table "form_instances", :force => true do |t|
      t.column "form_type_id",       :integer
      t.column "form_data_id",       :integer
      t.column "form_data_type",     :string
      t.column "store_id",           :integer
      t.column "customer_id",        :integer
      t.column "user_id",            :integer
      t.column "status_number",      :integer,  :default => 1
      t.column "created_at",         :datetime
      t.column "submitted",          :boolean
      t.column "has_been_submitted", :boolean,  :default => false
    end

    create_table "form_types", :force => true do |t|
      t.column "friendly_name",            :string
      t.column "name",                     :string
      t.column "can_have_notes",           :boolean
      t.column "can_have_multiple_drafts", :boolean
    end

    create_table "logs", :force => true do |t|
      t.column "created_at",  :datetime
      t.column "log_type",    :string
      t.column "data",        :string
      t.column "object_id",   :integer
      t.column "object_type", :string
      t.column "agent_id",    :integer
      t.column "agent_type",  :string
    end

    create_table "notes", :force => true do |t|
      t.column "form_instance_id", :integer
      t.column "author_type",      :string
      t.column "author_id",        :integer
      t.column "text",             :text
      t.column "created_at",       :datetime
      t.column "attachment",       :string
    end

    create_table "stores", :force => true do |t|
      t.column "alias",          :string,   :limit => 25
      t.column "friendly_name",  :string,   :limit => 50
      t.column "address",        :string
      t.column "contact_person", :string,   :limit => 25
      t.column "telephone",      :string,   :limit => 20
      t.column "tax_id",         :string
      t.column "created_at",     :datetime
      t.column "updated_at",     :datetime
      t.column "form_type_ids",  :string,                 :default => "--- []\n\n"
    end

    create_table "users", :force => true do |t|
      t.column "username",             :string,   :limit => 25
      t.column "friendly_name",        :string,   :limit => 50
      t.column "store_id",             :integer
      t.column "crypted_password",     :string,   :limit => 40
      t.column "salt",                 :string,   :limit => 40
      t.column "encryption_key",       :binary
      t.column "status",               :string
      t.column "password_change_date", :string
      t.column "activated_at",         :datetime
      t.column "created_at",           :datetime
      t.column "updated_at",           :datetime
      t.column "form_type_ids",        :string,                 :default => "--- []\n\n"
    end
  end

  def self.down
    drop_table :admins
    drop_table :form_instances
    drop_table :form_types
    drop_table :logs
    drop_table :notes
    drop_table :stores
    drop_table :users
  end
end