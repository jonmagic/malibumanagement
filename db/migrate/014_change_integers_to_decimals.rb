class ChangeIntegersToDecimals < ActiveRecord::Migration
  def self.up
    change_column :direct_deposit_authorizations, :amount, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :actual_debit, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :total_sales, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :total_revenue, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :previous_year_sales, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :goal_for_month, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :actual_vs_goal_diff_for_month, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :cash_error, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :payroll_percent_for_month, :decimal, :precision => 8, :scale => 2
    change_column :manager_reports, :store_inspection_grade, :string
    change_column :sales_reports, :store_daily_sales, :decimal, :precision => 8, :scale => 2
    change_column :sales_reports, :goal_for_day, :decimal, :precision => 8, :scale => 2
    change_column :sales_reports, :total_revenue, :decimal, :precision => 8, :scale => 2
    change_column :sales_reports, :actual_vs_goal_diff_for_day, :decimal, :precision => 8, :scale => 2
    change_column :sales_reports, :cash_error, :decimal, :precision => 8, :scale => 2
  end

  def self.down
  end
end
