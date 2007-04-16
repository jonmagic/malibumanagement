# THIS FORM IS NOT QUITE FINISHED YET!

require 'digest/sha1'
class TimeOffRequest < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  attr_accessor :save_status

  attr_accessor :employee_username, :employee_password,
                :admin_review_username, :admin_review_password,
                :admin_approval_username, :admin_approval_password,

  before_update :create_signature_hashes

  def is_signed?
    !self.digital_signature_hash.blank? && !self.digital_signature_id.blank?
  end

  private
    # Validate that the sign_username and sign_password provided map to a real user and authenticate successfully.
    def validate_on_update
      if self.is_signed?
#Only for each signature that is trying to be resigned
        errors.add_to_base("CANNOT re-sign this form once it is signed!")
#****
#Validate that no fields are changed once the employee has signed.
#****
      else
#Validate only for each username and password given
        user = User.authenticate(self.sign_username, self.sign_password, Thread.current['user'].domain)
  logger.error "NOT Valid user!!" unless User.authenticate(self.sign_username, self.sign_password, Thread.current['user'].domain)
        errors.add(:sign_username, "could not be validated. Please check your username and password and try again.") unless user
        errors.add(:social_security_number, "needs to be set in #{self.sign_username}'s profile to be able to sign.") if !user.nil? && user.social_security_number.blank?
#****
      end
    end

    # Grab the user who authenticated and store in self.digital_signature_hash a hash of the user's social-security number and self.created_at
    def create_signature_hash
#Create only for those that have been authenticated
      user = User.find_by_username_and_store_id(self.sign_username, Thread.current['user'].store_id)
      self.signer = user
      self.digital_signature_hash = Digest::SHA1.hexdigest("--#{user.social_security_number}--#{self.instance.created_at}--")
      self.digital_signature_date = Time.now
#****
    end
end
