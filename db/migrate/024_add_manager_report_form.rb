class AddManagerReportForm < ActiveRecord::Migration
  def self.up
    create_table :manager_reports do |t|
      t.column :overview,         :text
      t.column :actual_debit,     :integer
      t.column :number_of_tans,   :integer
      t.column :total_sales,      :integer
      t.column :total_revenue,    :integer
      t.column :previous_year_sales,  :integer
      t.column :previous_year_tans,   :integer
      t.column :goal_for_month,   :integer
      t.column :action_plan_for_next_month, :text
      t.column :meetings_training_agenda,   :text
      t.column :cash_error,       :integer
      t.column :payroll_percent_for_month,  :integer
      t.column :store_inspection_grade,     :integer
      t.column :employees,        :string #serialized add/remove list
      t.column :maintenance_requests, :string #serialized add/remove list
      t.column :suggestions,      :text
      t.column :store_needs,      :text
      t.column :inventory_items_error,  :string
      t.column :action_plan_to_correct_problems,  :string
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts) VALUES("Manager Report", "ManagerReport", 1, 0)'
  end

  def self.down
    drop_table :manager_reports
    execute 'DELETE FROM form_types WHERE name="ManagerReport"'
  end
end
