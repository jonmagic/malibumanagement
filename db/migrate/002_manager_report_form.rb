class ManagerReportForm < ActiveRecord::Migration
  def self.up
    create_table "manager_reports", :force => true do |t|
      t.column "overview",                        :text
      t.column "actual_debit",                    :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "number_of_tans",                  :integer
      t.column "total_sales",                     :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "total_revenue",                   :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "previous_year_sales",             :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "previous_year_tans",              :integer
      t.column "goal_for_month",                  :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "actual_vs_goal_diff_for_month",   :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "action_plan_for_next_month",      :text
      t.column "meetings_training_agenda",        :text
      t.column "cash_error",                      :integer, :limit => 10, :precision => 10, :scale => 0
      t.column "payroll_percent_for_month",       :integer
      t.column "store_inspection_grade",          :integer
      t.column "employees",                       :string
      t.column "maintenance_requests",            :string
      t.column "suggestions",                     :text
      t.column "store_needs",                     :text
      t.column "inventory_items_error",           :string
      t.column "action_plan_to_correct_problems", :string
    end
  end

  def self.down
    drop_table :manager_reports
  end
end