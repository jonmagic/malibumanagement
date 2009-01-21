class WrittenWarningForm < ActiveRecord::Migration
  def self.up
    create_table :written_warnings do |t|
      t.column :employee_name,      :string
      t.column :incident_date,      :datetime
      t.column :description,        :text
      t.column :employee_sign_id,       :integer
      t.column :employee_sign_hash,     :string
      t.column :employee_sign_date,     :datetime
      t.column :manager_sign_id,       :integer
      t.column :manager_sign_hash,     :string
      t.column :manager_sign_date,     :datetime
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Written Warning", "WrittenWarning", 1, 1, 1, 0)'
  end

  def self.down
    drop_table :written_warnings
    execute 'DELETE FROM form_types WHERE name="WrittenWarning"'
    execute 'DELETE FROM form_instances WHERE data_type="WrittenWarning"'
  end
end
