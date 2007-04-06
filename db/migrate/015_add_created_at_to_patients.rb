class AddCreatedAtToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :created_at,     :datetime
    Customer.find(:all).each do |p|
      p.created_at = 24.hours.ago
      p.save
    end
  end

  def self.down
    remove_column :customers, :created_at
  end
end
