class PpaDecimal < ActiveRecord::Migration
  def self.up
    change_column :sales_reports,   :store_ppa, :decimal, :precision => 8, :scale => 2
    remove_column :sales_reports,   :actual_vs_goal_diff_for_day
    remove_column :manager_reports, :actual_vs_goal_diff_for_month
  end

  def self.down
    change_column :sales_reports, :store_ppa, :integer
    add_column :sales_reports, :actual_vs_goal_diff_for_day, :decimal, :precision => 8, :scale => 2
    add_column :manager_reports, :actual_vs_goal_diff_for_month, :decimal, :precision => 8, :scale => 2
  end
end
