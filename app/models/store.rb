require 'digest/sha1'
class Store < ActiveRecord::Base
  has_many :users, :dependent => :destroy, :conditions => 'username<>"#{self.alias}"'
  has_one  :admin, :class_name => 'User', :conditions => 'username="#{self.alias}"', :dependent => :destroy
  has_many :patients, :dependent => :destroy
  has_and_belongs_to_many :form_types
  has_many :form_instances, :dependent => :destroy
    has_many :drafts,    :class_name => 'FormInstance', :conditions => "status_number=1"
    has_many :submitted, :class_name => 'FormInstance', :conditions => "status_number=2"
    has_many :reviewing,  :class_name => 'FormInstance', :conditions => "status_number=3"
    has_many :archived,  :class_name => 'FormInstance', :conditions => "status_number=4"
  has_many :logs, :as => :object

  validates_presence_of     :alias, :friendly_name, :address, :telephone
  validates_length_of       :alias, :within => 5..25
  validates_uniqueness_of   :alias, :case_sensitive => false

  before_create  :make_encryption_key

  def self.form_model(form_type_name)
    type = FormType.find_by_name(form_type_name)
    type.nil? ? nil : type.name.constantize
  end
  #This is the proxy method to the form data records
  def form_model(form_type_name)
    type = FormType.find_by_name(form_type_name)
    # logger.error "Attempted unpermitted FormType access: Store includes " + (self.form_type_ids.join(', ')) + ", but NOT #{type}?" unless self.form_types.include?(type)
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
#      if operation == 'activate' #Activate
#        if activation_code_valid
#          errors.add(:username, "can't be blank") if username.blank? && old_user.username.blank?
#          errors.add(:password, "can't be blank") if password.blank? && old_user.crypted_password.blank?
#        else
#          errors.add(:activation_code, "is not valid.") unless @just_activated
#        end
#      else
#        if operation == 'password_change' #Password Change
##Need to add in validations here
#          
#        else #Other Update function: restrain from changing username, password, activation_code (save(false) to inject activation_code)
##Need to add in validations here
#          
#        end
#      end
      if !old_store.blank?
        errors.add_to_base("Only Malibu Admin users can modify your assigned forms.") if !form_type_ids.blank? && !old_store.form_type_ids.blank? && !(form_type_ids == old_store.form_type_ids)
        errors.add(:alias, "cannot be changed once created!") if !self.alias.blank? && !old_store.alias.blank? && !(self.alias == old_store.alias)
      end
    end

    def make_encryption_key
      self.encryption_key = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end 

end
