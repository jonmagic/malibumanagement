require 'digest/sha1'
class HandbookAcknowledgement < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  belongs_to :signer, :class_name => 'User', :foreign_key => 'digital_signature_id'

# Has two columns:
  # "digital_signature_id" => :integer
  # "digital_signature_hash" => :string
# The form should include several paragraphs (explaining that you are signing for reading the handbook) and then two fields - username, and password for the person who wants to sign.
# in validation of the form, we will check the authentication of that user, then before_save, create the 'digital_signature_hash' from the user's social-security number and the time the form_instance was created.
  attr_accessor :sign_username, :sign_password,
                :save_status
  before_update :create_signature_hash

  def is_signed?
# logger.info !self.digital_signature_hash.blank? && !self.digital_signature_id.blank? ? "Is Signed!" : "Is NOT Signed!"
    return !self.digital_signature_hash.blank? && !self.digital_signature_id.blank?
  end

  private
    # Validate that the sign_username and sign_password provided map to a real user and authenticate successfully.
    def validate_on_update
      create_signature_hash if !self.sign_username.blank? && !self.sign_password.blank?
# logger.error "Validating...!!"
      orig = self.class.find(self.id)
      if orig.is_signed?
        self.attributes = {:digital_signature_hash => orig.digital_signature_hash, :digital_signature_id => orig.digital_signature_id, :digital_signature_date => orig.digital_signature_date}
        # errors.add_to_base("CANNOT re-sign this form once it is signed!")
      else
        errors.add(:sign_username, "can't be blank") if sign_username.blank?
        errors.add(:sign_password, "can't be blank") if sign_password.blank?
        user = User.authenticate(self.sign_username, self.sign_password, Thread.current['user'].domain)
# logger.error "NOT Valid user!!" unless User.authenticate(self.sign_username, self.sign_password, Thread.current['user'].domain)
        errors.add(:sign_username, "could not be validated. Please check your username and password and try again.") unless user
        errors.add(:social_security_number, "needs to be set in #{self.sign_username}'s profile to be able to sign.") if !user.nil? && user.social_security_number.blank?
      end
    end

    # Grab the user who authenticated and store in self.digital_signature_hash a hash of the user's social-security number and self.created_at
    def create_signature_hash
      # user = User.find_by_username_and_store_id(self.sign_username, Thread.current['user'].store_id)
      if user = User.authenticate(self.sign_username, self.sign_password, Thread.current['user'].domain)
        self.signer = user
        self.digital_signature_hash = Digest::SHA1.hexdigest("--#{user.social_security_number}--#{self.instance.created_at}--")
        self.digital_signature_date = Time.now
        self.save_status = self.save_status.to_s + " Signature accepted. Reload this page to see the digital fingerprint."
      else
        logger.info "Couldn't authenticate #{self.sign_username} with password '#{self.sign_password}'"
      end
    end
end
