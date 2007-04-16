class NoticeOfTerminationForm < ActiveRecord::Migration
  def self.up
    create_table :notice_of_terminations, :force => true do |t|
      t.column :employee_name,          :string
      t.column :reason_for_termination, :text
      t.column :manager_signature_id,   :integer
      t.column :manager_signature_hash, :string
      t.column :manager_signature_date, :datetime
      t.column :regional_signature_id,  :integer
      t.column :regional_signature_hash, :string
      t.column :regional_signature_date,  :datetime
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Notice Of Termination", "NoticeOfTermination", 1, 1, 1, 0)'
    #****
  end

  def self.down
    drop_table :notice_of_terminations
    execute 'DELETE FROM form_types WHERE name="NoticeOfTermination"'
    execute 'DELETE FROM form_instances WHERE data_type="NoticeOfTermination"'
  end
end
