class IncidentReportForm < ActiveRecord::Migration
  def self.up
    create_table :incident_reports do |t|
      t.column :employee_name,      :string
      t.column :incident_date,      :datetime
      t.column :description,        :text
      t.column :manager_sign_id,    :integer
      t.column :manager_sign_hash,  :string
      t.column :manager_sign_date,  :datetime
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Incident Report", "IncidentReport", 1, 1, 1, 0)'
  end

  def self.down
    drop_table :incident_reports
    execute 'DELETE FROM form_types WHERE name="IncidentReport"'
    execute 'DELETE FROM form_instances WHERE data_type="IncidentReport"'
  end
end
