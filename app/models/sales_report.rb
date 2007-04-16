class SalesReport < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
# These should be looking for data_id == self.id and data_type == BasicForm in form_instances, in order to match up with doctor_id/patient_id/form_type_id
#These are actually not necessary!!
  has_many :stores, :finder_sql => 'SELECT stores.* FROM stores,form_instances fi WHERE fi.data_id=#{id} AND fi.data_type="SalesReport" AND stores.id=fi.store_id'
  has_many :form_types, :finder_sql => 'SELECT form_types.* FROM form_types,form_instances fi WHERE fi.data_id=#{id} AND fi.data_type="SalesReport" AND form_types.id=fi.form_type_id'
  has_many :notes, :finder_sql => 'SELECT notes.* FROM notes,form_instances fi WHERE fi.data_id=#{id} AND fi.data_type="SalesReport" AND AND notes.form_instance_id=fi.id'
  has_many :logs, :as => 'object'
  serialize :employee_names, Array
  serialize :employee_sales, Array
  serialize :employee_ppa, Array
  serialize :employee_tans, Array
  attr_accessor :save_status

end
