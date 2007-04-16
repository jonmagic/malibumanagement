class SalesReportForm < ActiveRecord::Migration
  def self.up
    create_table :sales_reports, :force => true do |t|
      t.column :store_daily_sales,       :decimal
      t.column :opening_checklist,       :boolean
      t.column :closing_checklist,       :boolean
      t.column :daily_cleaning,          :boolean
      t.column :goal_for_day,            :decimal
      t.column :total_revenue,           :decimal
      t.column :actual_vs_goal_diff_for_day, :decimal
      t.column :employee_names,          :string, :default => [''].to_yaml
      t.column :employee_sales,          :string, :default => [''].to_yaml
      t.column :employee_ppa,            :string, :default => [''].to_yaml
      t.column :employee_tans,           :string, :default => [''].to_yaml
      t.column :store_ppa,               :integer
      t.column :total_tans,              :integer
      t.column :cash_error,              :decimal
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts) VALUES("Sales Report", "SalesReport", 1, 0)'
    #****
  end

  def self.down
    drop_table :sales_reports
    execute 'DELETE FROM form_types WHERE name="SalesReport"'
    execute 'DELETE FROM form_instances WHERE data_type="SalesReport"'
  end
end