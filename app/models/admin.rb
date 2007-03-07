require 'digest/sha1'
class Admin < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :operation #for the status of activating to enable the activation validations

  validates_presence_of     :email, :friendly_name
  validates_length_of       :email, :within => 3..100,          :if => :email_present?
  validates_uniqueness_of   :email, :case_sensitive => false
  validates_length_of       :username, :within => 3..40,        :if => :username_present?
  validates_uniqueness_of   :username, :case_sensitive => false, :if => :username_present?
  validates_presence_of     :password_confirmation,             :if => :password_present?
  validates_confirmation_of :password,                          :if => :password_present?
  validates_length_of       :password, :within => 4..40,        :if => :password_present?

  before_save               :encrypt_password
  after_update              :activate
  before_create             :make_activation_code 
  
  def activated?
    adm = Admin.find_by_activation_code(activation_code)
    adm && !adm.username.blank? && !adm.password.blank? && adm.activation_code.blank?
  end

  def domain
    "manage"
  end

  def self.is_admin?(user)
    mock = Admin.find_by_username(user.username)
    mock.blank? ? nil : mock.email == user.email
  end

  def is_admin?
    true
  end
  def Admin.is_doctor?
    false
  end
  def is_doctor?
    false
  end
  def is_doctor_or_admin?
    is_doctor? || is_admin?
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @just_activated
  end 

  def self.valid_username?(username)
    u = find :first, :conditions => ['username = ?', username]
    !u.blank? ? u : nil
  end

  # Authenticates a user by their username and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, password, domain='manage')
#    u = find :first, :conditions => ['username = ? and activated_at IS NOT NULL', username] # need to get the salt
    u = find :first, :conditions => ['username = ?', username] # :first, :conditions => ['username = ?', username] # need to get the salt
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

  def changing_login
    @login_change = true
  end

  protected


#Need to validate_uniqueness_of email address throughout User model as well!
    def validate_on_update
      old_admin = Admin.find_by_activation_code(activation_code) if !activation_code.blank?
      activation_code_valid = !old_admin.blank?
      #If the activation_code isn't present, the id should be, if we happen to be at the point of validation
      old_admin = Admin.find_by_id(id) if !activation_code_valid

      if operation == 'activate' #Activate
        if activation_code_valid
          errors.add(:username, "can't be blank") if username.blank? && old_admin.username.blank?
          errors.add(:password, "can't be blank") if password.blank? && old_admin.crypted_password.blank?
        else
          errors.add(:activation_code, "is not valid.") unless @just_activated
        end
      else
        if operation == 'password_change' #Password Change
#Need to add in validations here
          
        else #Other Update function: restrain from changing username, password, activation_code (save(false) to inject activation_code)
#Need to add in validations here
          
        end
      end
      if !old_admin.blank?
        errors.add(:username, "cannot be changed once created!") if !username.blank? && !old_admin.username.blank? && !(username == old_admin.username)
        errors.add(:activation_code, "cannot be changed!") unless activation_code == old_admin.activation_code or @just_activated
      end
    end

    # This automatically activates a user if the prerequisites are met
    def activate
      adm = Admin.find_by_activation_code(activation_code) if !activation_code.blank?
      return nil if adm.blank?
      if !adm.username.blank? and !adm.crypted_password.blank? and !adm.activation_code.blank?
        @just_activated = true
        self.activated_at = Time.now.utc
        self.activation_code = nil
#Interesting stuff happens here:
# validate_on_update runs, after which this method (activate) runs. In order to save, it has to validate_on_update again.
# In the first validate_on_update, it has an activation_code present, but after passing through this, it doesn't, so
# validate_on_update has to find by id instead. This should be reliable, but maybe just touchy if someone changes anything.
        self.save
      end
    end

    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{username}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def make_activation_code
      self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    end

    def email_present?
      !email.blank?
    end

    def username_present?
      !username.blank?
    end

    def password_present?
      !password.blank?
    end

end
