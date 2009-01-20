require 'digest/sha1'
class User < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :store
  has_many :form_instances
  has_many :drafts,     :class_name => 'FormInstance', :conditions => "status_number=1"
  has_many :submitted,  :class_name => 'FormInstance', :conditions => "status_number=2"
  has_many :reviewing,  :class_name => 'FormInstance', :conditions => "status_number=3"
  has_many :archived,   :class_name => 'FormInstance', :conditions => "status_number=4"
  has_many :assigned,   :class_name => 'FormInstance', :foreign_key => 'assigned_to'

  has_many :notes, :as => :author
  has_many :logs,  :as => :agent

  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :operation

  validates_presence_of     :password, :password_confirmation,    :if => :not_attr_update?
  validates_presence_of     :store_id, :friendly_name, :username, :social_security_number
  validates_length_of       :username, :within => 3..40,          :if => :username_present?
  # validates_presence_of     :password_confirmation
  validates_confirmation_of :password
  validates_length_of       :password, :within => 4..40,          :if => :password_present?

  before_save               :encrypt_password
  before_save               :normalize_blank_assigned_form_types

  serialize :form_type_ids, Array
  def form_types
    FormType.find(self.form_type_ids)
  end

  def domain
    self.store.alias
  end
  def default_layout
    'store'
  end
  
  def self.is_store_admin?(user)
    u = User.find_by_username(user)
    u.nil? ? nil : u.is_store_admin?
  end
  def is_store_admin?
    self.is_store_admin
  end
  def is_admin?
    false
  end
  def is_store_user?
    true
  end
  def is_store_admin_or_admin?
    is_store_admin?
  end

  def self.valid_username?(username)
    u = find :first, :conditions => ['username = ?', username]
    !u.blank? ? u : nil
  end

  def drafts_of_type(form_type)
    FormInstance.find_all_by_user_id_and_data_type_and_status_number(self.id, form_type, 'draft'.as_status.number)
  end

  def others_form_instances
    FormInstance.find(:all, :conditions => ['store_id=? AND user_id!=?', self.store.id, self.id])
  end
  def forms_with_status(status)
    FormInstance.find_all_by_user_id_and_status_number(self.id, status.as_status.number)
  end
  def others_forms_with_status(status)
    FormInstance.find(:all, :conditions => ['store_id=? AND user_id!=? AND status_number=?', self.store.id, self.id, status.as_status.number])
  end

  # Authenticates a user by their username and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password, stor_alias)
    return nil if !username || !password || !stor_alias
    u = find :first, :conditions => ['username = ? and store_id = ?', username, Store.id_of_alias(stor_alias)] # :first, :conditions => ['username = ?', username] # need to get the salt
    return u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def changing_login
    @login_change = true
  end

  protected

    # validates_uniqueness_of   :username, :case_sensitive => false,  :if => :username_present?
    def validate_on_create
      errors.add(:username, "is already taken for store #{self.store.friendly_name}") if User.find_by_username_and_store_id(self.username, self.store_id)
    end

    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{username}--") if new_record?
      self.password_change_date = Time.now.utc
      self.crypted_password = encrypt(password)
    end
    
    def username_present?
      !self.username.blank?
    end
    def password_present?
      !self.password.blank?
    end
    def not_attr_update?
      !(self.operation == 'attr_update') && self.password.blank?
    end

# Because when the checkboxes come back with none checked, it doesn't update, so we include a blank one - which doesn't go well with finding by '' id.
    def normalize_blank_assigned_form_types
      # Nil any blank elements from the list
      self.form_type_ids = self.form_type_ids.collect! {|ftid| ftid == "" ? nil : ftid }
      # Remove the nil elements
      self.form_type_ids.compact!
    end
end
