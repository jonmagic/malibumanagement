class SalesReport < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
# These should be looking for data_id == self.id and data_type == BasicForm in form_instances, in order to match up with doctor_id/patient_id/form_type_id
#These are actually not necessary!!
  has_many :logs, :as => 'object'
  serialize :employee_names, Array
  serialize :employee_sales, Array
  serialize :employee_ppa, Array
  serialize :employee_tans, Array
  attr_accessor :save_status

  def actual_vs_goal_diff_for_day
    self.total_revenue.to_f - self.goal_for_day.to_f
  end
end
