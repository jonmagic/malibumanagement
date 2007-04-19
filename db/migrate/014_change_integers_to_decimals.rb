class ChangeIntegersToDecimals < ActiveRecord::Migration
  def self.up
    change_column :direct_deposit_authorizations, :amount, :decimal
    change_column :manager_reports, :actual_debit, :decimal
    change_column :manager_reports, :total_sales, :decimal
    change_column :manager_reports, :total_revenue, :decimal
    change_column :manager_reports, :previous_year_sales, :decimal
    change_column :manager_reports, :goal_for_month, :decimal
    change_column :manager_reports, :actual_vs_goal_diff_for_month, :decimal
    change_column :manager_reports, :cash_error, :decimal
    change_column :manager_reports, :payroll_percent_for_month, :decimal
    change_column :manager_reports, :store_inspection_grade, :string
    change_column :sales_reports, :store_daily_sales, :decimal
    change_column :sales_reports, :goal_for_day, :decimal
    change_column :sales_reports, :total_revenue, :decimal
    change_column :sales_reports, :actual_vs_goal_diff_for_day, :decimal
    change_column :sales_reports, :cash_error, :decimal
  end

  def self.down
  end
end
