class AddInventoryToAllManagers < ActiveRecord::Migration
  def self.up
    inv = FormType.find_by_name('InventoryReport').id
    User.find_by_sql('SELECT * FROM users').each do |user|
      if user.is_store_admin?
        user.form_type_ids.push(inv) unless user.form_type_ids.include?(inv)
        user.operation = 'attr_update'
        user.save!
      end
    end
  end

  def self.down
  end
end
