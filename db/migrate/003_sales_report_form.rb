class SalesReportForm < ActiveRecord::Migration
  def self.up
    create_table "sales_reports", :force => true do |t|
      t.column "store_daily_sales",       :integer
      t.column "opening",                 :boolean
      t.column "store_goal",              :boolean
      t.column "total_revenue",           :integer
      t.column "daily_cleaning",          :boolean
      t.column "plus_minus_goal_for_day", :integer
      t.column "employee_names",          :string
      t.column "employee_sales",          :string
      t.column "employee_ppa",            :string
      t.column "employee_tans",           :string
      t.column "store_ppa",               :integer
      t.column "total_tans",              :integer
      t.column "cash_error",              :integer
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts) VALUES("Sales Report", "SalesReport", 1, 0)'
    #****
  end

  def self.down
    drop_table :sales_reports
  end
end