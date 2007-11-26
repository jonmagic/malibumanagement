class AddGotoTransactions < ActiveRecord::Migration
  def self.up
    create_table :goto_transactions, :force => true do |t|
      t.column :batch_id,             :integer
      t.column :client_id,            :integer
      t.column :location,             :string
      t.column :first_name,           :string
      t.column :last_name,            :string
      t.column :bank_routing_number,  :string
      t.column :bank_account_number,  :string
      t.column :name_on_card,         :string
      t.column :credit_card_number,   :string
      t.column :expiration,           :string
      t.column :amount,               :string
      t.column :type,                 :string
      t.column :account_type,         :string
      t.column :authorization,        :string
      # Recorded bits
      t.column :no_eft,               :boolean, :default => false # Shows up for 'Missing' search
      t.column :goto_invalid,         :string, :default => [].to_yaml  # Shows up for 'Invalid' search
      t.column :transaction_id,       :integer # OTNum field
      t.column :note_id,              :integer # OTNum field
      t.column :recorded,             :boolean
      # Response attributes, :string
      t.column :order_number, :string
      t.column :sent_date,    :string
      t.column :tran_date,    :string
      t.column :tran_time,    :string
      t.column :status,       :string
      t.column :description,  :string
      t.column :term_code,    :string
      t.column :auth_code,    :string
    end
  end

  def self.down
    drop_table :goto_transactions
  end
end
