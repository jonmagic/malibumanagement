require 'digest/sha1'
class Store < ActiveRecord::Base
  has_many :users, :dependent => :destroy
  has_many :admins, :class_name => 'User', :conditions => 'is_admin_user=1', :dependent => :destroy
  has_one  :vintage_admin, :class_name => 'User', :conditions => 'username="#{self.alias}"', :dependent => :destroy
  has_many :form_instances, :dependent => :destroy
    has_many :drafts,    :class_name => 'FormInstance', :conditions => "status_number=1"
    has_many :submitted, :class_name => 'FormInstance', :conditions => "status_number=2"
    has_many :reviewing, :class_name => 'FormInstance', :conditions => "status_number=3"
    has_many :archived,  :class_name => 'FormInstance', :conditions => "status_number=4"
  has_many :logs, :as => :object

  validates_presence_of     :alias, :friendly_name, :address, :telephone
  validates_length_of       :alias, :within => 5..25
  validates_uniqueness_of   :alias, :case_sensitive => false

  serialize :form_type_ids, Array
  def form_types
    FormType.find(self.form_type_ids)
  end
  def form_types=(ary)
    self.form_type_ids = ary.collect do |ft|
      ft.id.to_s
    end
  end

  def self.form_model(form_type_name)
    type = FormType.find_by_name(form_type_name)
    type.nil? ? nil : type.name.constantize
  end
  #This is the proxy method to the form data records
  def form_model(form_type_name)
    type = FormType.find_by_name(form_type_name)
    return nil unless self.form_types.include?(type)
    type.nil? ? nil : type.name.constantize
  end

  def self.exists?(stor_alias)
    !Store.find_by_alias(stor_alias).blank?
  end

  def self.id_of_alias(stor_alias)
    stor = Store.find_by_alias(stor_alias)
    stor.nil? ? nil : stor.id
  end

  def drafts_of_type(form_type)
    FormInstance.find_all_by_store_id_and_data_type_and_status_number(self.id, form_type, 'draft'.as_status.number)
  end

  def forms_with_status(status)
# logger.error "Finding by #{self.alias} (#{self.id}) and #{status} (#{status.as_status.number})."
    FormInstance.find_all_by_store_id_and_status_number(self.id, status.as_status.number)
  end

  protected
    def validate_on_create
      errors.add(:alias, "cannot be set to <em>\"#{self.alias}\"</em>. Please choose another alias.") if ['pages', 'login', 'logout', 'manage', 'malibu'].include?(self.alias)
    end

    def validate_on_update
      old_store = Store.find_by_id(id)
      if !old_store.blank?
        # errors.add_to_base("Only Malibu Admin users can modify your assigned forms.") if !current_user.is_admin? && !form_type_ids.blank? && !old_store.form_type_ids.blank? && !(form_type_ids == old_store.form_type_ids)
        errors.add(:alias, "cannot be changed once created!") if !self.alias.blank? && !old_store.alias.blank? && !(self.alias == old_store.alias)
      end
    end

end
