class PerformanceReviewForm < ActiveRecord::Migration
  def self.up
    create_table :performance_reviews do |t|
      t.column :employee_name,        :string
      t.column :good_attendance,      :boolean
      t.column :completes_checklists, :boolean
      t.column :cleaning_schedule,    :boolean
      t.column :understands_packages, :boolean
      t.column :understands_rotation, :boolean
      t.column :pleasant_to_clients,  :boolean
      t.column :run_computer,         :boolean
      t.column :paperwork,            :boolean
      t.column :no_shortages,         :boolean
      t.column :follows_instructions, :boolean
      t.column :open_close_unassisted,  :boolean
      t.column :manager_sign_id,        :integer
      t.column :manager_sign_hash,      :string
      t.column :manager_sign_date,      :datetime
      t.column :manager_comments,       :string
      t.column :employee_sign_id,       :integer
      t.column :employee_sign_hash,     :string
      t.column :employee_sign_date,     :datetime
      t.column :employee_comments,      :string
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Performance Review", "PerformanceReview", 1, 1, 1, 0)'
    #****
  end

  def self.down
    drop_table :performance_reviews
    execute 'DELETE FROM form_types WHERE name="PerformanceReview"'
    execute 'DELETE FROM form_instances WHERE data_type="PerformanceReview"'
  end
end
