class TimeOffRequestForm < ActiveRecord::Migration
  def self.up
    create_table :time_off_requests, :force => true do |t|
      t.column :employee_name,            :string
      t.column :date,                     :date
      t.column :time_off_kind,            :string  # should be either vacation or personal/sick
      t.column :dates_requested,          :string
      t.column :time_left_before_days,    :integer
      t.column :time_left_after_days,     :integer
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Time Off Request", "TimeOffRequest", 1, 0, 1, 0)'
    #****
  end

  def self.down
    drop_table :time_off_requests
    execute 'DELETE FROM form_types WHERE name="TimeOffRequest"'
    execute 'DELETE FROM form_instances WHERE data_type="TimeOffRequest"'
  end
end
