class ManagerReport < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  attr_accessor :save_status

# Attr_accessible is here to eliminate irrelevant values given by a patient object when attributes are created/updated.
  attr_accessible :overview, :actual_debit, :number_of_tans, :total_sales, :total_revenue, :previous_year_sales, :previous_year_tans, :goal_for_month, :action_plan_for_next_month, :meetings_training_agenda, :cash_error, :payroll_percent_for_month, :store_inspection_grade, :employees, :maintenance_requests, :suggestions, :store_needs, :inventory_items_error, :action_plan_to_correct_problems

  def actual_vs_goal_diff_for_month
    self.total_revenue.to_f - self.goal_for_month.to_f
  end

end
