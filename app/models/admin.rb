require 'digest/sha1'
class Admin < ActiveRecord::Base
  has_many :notes, :as => :author
  has_many :logs,  :as => :agent
# These won't work because they would need an 'admin_id' in form_instances. Do we want that?
  # has_many :reviewing, :class_name => 'FormInstance', :conditions => "status_number=3"
  # has_many :archived, :class_name => 'FormInstance', :conditions => "status_number=4"

  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :operation #just to give the controller the ability to enable the activation validations

  validates_presence_of     :password, :password_confirmation,    :if => :not_attr_update?
  validates_presence_of     :username, :friendly_name, :social_security_number, :if => :not_password_change?
  validates_length_of       :username, :within => 3..40,          :if => :username_present?
  validates_uniqueness_of   :username, :case_sensitive => false,  :if => :username_present?
  validates_confirmation_of :password
  validates_length_of       :password, :within => 4..40,          :if => :password_present?

  before_save               :encrypt_password

  def domain
    'malibu'
  end
  def default_layout
    'admin'
  end
  def store
    domain
  end

  def is_admin?
    true
  end
  def is_store_admin?
    false
  end
  def is_store_user?
    false
  end
  def is_store_admin_or_admin?
    true
  end

  def self.valid_username?(username)
    u = Admin.find_by_username(username)
    !u.blank? ? u : nil
  end

  # Authenticates a user by their username and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password)
    u = Admin.find_by_username(username) # need to get the salt
    u && u.authenticated?(password) ? u : nil
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

  protected

    def encrypt_password
      return if self.password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{self.username}--") if self.new_record?
      self.crypted_password = encrypt(self.password)
    end

    def username_present?
      !self.username.blank?
    end

    def password_present?
      !self.password.blank?
    end
    
    def not_password_change?
      !(self.operation == 'changing_password')
    end
    def not_attr_update?
      !(self.operation == 'attr_update')
    end
end
