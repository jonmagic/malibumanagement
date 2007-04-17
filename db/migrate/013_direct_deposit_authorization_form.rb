class DirectDepositAuthorizationForm < ActiveRecord::Migration
  def self.up
    create_table :direct_deposit_authorizations do |t|
      t.column :employee_name,              :string
      t.column :employee_id_number,         :integer
      t.column :depository_bank,            :string
      t.column :bank_city,                  :string
      t.column :bank_branch,                :string
      t.column :bank_routing_number,        :integer
      t.column :bank_account_number,        :integer
      t.column :account_type,               :string
      t.column :amount,                     :integer
      t.column :effective_date,             :date
      t.column :date_received,              :date
      t.column :date_pre_note_sent,         :date
      t.column :date_of_first_payroll,      :date
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Direct Deposit Authorization", "DirectDepositAuthorization", 1, 1, 1, 1)'
  end

  def self.down
    drop_table :direct_deposit_authorizations
    execute 'DELETE FROM form_types WHERE name="DirectDepositAuthorization"'
    execute 'DELETE FROM form_instances WHERE data_type="DirectDepositAuthorization"'
  end
end
