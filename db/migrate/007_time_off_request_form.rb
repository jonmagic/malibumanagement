class TimeOffRequestForm < ActiveRecord::Migration
  def self.up
    create_table :time_off_requests, :force => true do |t|
      t.column :is_vacation,              :boolean  # If not, it is personal/sick time
      t.column :dates_requested,          :string
      t.column :employee_signature_id,    :integer  # Employee signature
      t.column :employee_signature_hash,  :string
      t.column :employee_signature_date,  :datetime
      t.column :admin_review_id,          :integer  # Admin signature
      t.column :admin_review_hash,        :string
      t.column :admin_review_date,        :datetime
      t.column :time_left_before_days,    :integer
      t.column :time_left_after_days,     :integer
      t.column :admin_approval_id,        :integer  # Admin signature
      t.column :admin_approval_hash,      :string
      t.column :admin_approval_date,      :datetime
    end
    #Also add this form type into the form_types table
    # execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Time Off Request", "TimeOffRequest", 1, 1, 1, 0)'
    #****
  end

  def self.down
    drop_table :time_off_requests
    execute 'DELETE FROM form_types WHERE name="TimeOffRequest"'
    execute 'DELETE FROM form_instances WHERE data_type="TimeOffRequest"'
  end
end
