require 'digest/sha1'
class NoticeOfTermination < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  belongs_to :manager_signer, :class_name => 'User', :foreign_key => 'manager_signature_id'
  belongs_to :regional_signer, :class_name => 'Admin', :foreign_key => 'regional_signature_id'
  attr_accessor :save_status

# Has two columns:
  # "digital_signature_id" => :integer
  # "digital_signature_hash" => :string
# The form should include several paragraphs (explaining that you are signing for reading the handbook) and then two fields - username, and password for the person who wants to sign.
# in validation of the form, we will check the authentication of that user, then before_save, create the 'digital_signature_hash' from the user's social-security number and the time the form_instance was created.
  attr_accessor :manager_sign_username, :manager_sign_password,
                :regional_sign_username, :regional_sign_password
  before_update :create_signature_hashes

  def is_signed?
    manager_signed? && regional_signed?
  end
  def manager_signed?
    !self.manager_signature_hash.blank? && !self.manager_signature_id.blank?
  end
  def regional_signed?
    !self.regional_signature_hash.blank? && !self.regional_signature_id.blank?
  end

  private
    # Validate that the sign_username and sign_password provided map to a real user and authenticate successfully.
    def validate_on_update
      if self.manager_signed?
        errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.manager_sign_username.blank?
      else
        manager = User.authenticate(self.manager_sign_username, self.manager_sign_password, Thread.current['user'].domain)
        errors.add(:store_manager, "signature must be a store manager.") if !manager.nil? && !manager.is_store_admin?
        errors.add(:store_manager, "could not be validated. Please check your username and password and try again.") if !manager && !self.manager_sign_username.blank?
        errors.add(:social_security_number, "needs to be set in #{self.manager_sign_username}'s profile to be able to sign.") if !manager.nil? && manager.social_security_number.blank?
      end
      if self.regional_signed?
        errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.regional_sign_username.blank?
      else
        regional = Admin.authenticate(self.regional_sign_username, self.regional_sign_password)
        errors.add(:regional_manager, "could not be validated. Please check your username and password and try again.") if !regional && !self.regional_sign_username.blank?
        errors.add(:social_security_number, "needs to be set in #{self.regional_sign_username}'s profile to be able to sign.") if !regional.nil? && regional.social_security_number.blank?
      end
    end

    # Grab the user who authenticated and store in self.digital_signature_hash a hash of the user's social-security number and self.created_at
    def create_signature_hashes
      if !self.manager_sign_username.blank?
        manager = User.find_by_username_and_store_id(self.manager_sign_username, Thread.current['user'].store_id)
        self.manager_signer = manager
        self.manager_signature_hash = Digest::SHA1.hexdigest("--#{manager.social_security_number}--#{self.instance.created_at}--")
        self.manager_signature_date = Time.now
        self.save_status = self.save_status.to_s + " Store Manager signature accepted. Reload this page to see the digital fingerprint."
      end

      if !self.regional_sign_username.blank?
        regional = Admin.find_by_username(self.regional_sign_username)
        self.regional_signer = regional
        self.regional_signature_hash = Digest::SHA1.hexdigest("--#{regional.social_security_number}--#{self.instance.created_at}--")
        self.regional_signature_date = Time.now
        self.save_status = self.save_status.to_s + " Regional Manager signature accepted. Reload this page to see the digital fingerprint."
      end
    end
end
