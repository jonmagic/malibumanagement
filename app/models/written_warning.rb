require 'digest/sha1'
class WrittenWarning < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  belongs_to :manager_signer, :class_name => 'User', :foreign_key => 'manager_sign_id'
  belongs_to :employee_signer, :class_name => 'User', :foreign_key => 'employee_sign_id'
  attr_accessor :save_status
  
  attr_accessor :manager_sign_username, :manager_sign_password,
                :employee_sign_username, :employee_sign_password
  # before_update :create_signature_hashes

  def is_signed?
    manager_signed? && employee_signed?
  end
  def manager_signed?
    !self.manager_sign_hash.blank? && !self.manager_sign_id.blank?
  end
  def employee_signed?
    !self.employee_sign_hash.blank? && !self.employee_sign_id.blank?
  end

  private
    def validate_on_update
      # if self.class.find(self.id).manager_signed?
      #   errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.manager_sign_username.blank?
      # else
logger.error "Status: #{self.instance.status}"
        errors.add(:manager_sign_username, "can't be blank") if self.instance.status.as_status.number > 1 && manager_sign_username.blank? && !self.is_signed?

        if manager = User.authenticate(self.manager_sign_username, self.manager_sign_password, Thread.current['user'].domain)
          if manager.is_store_admin?
            if manager.social_security_number.blank?
              errors.add(:social_security_number, "needs to be set in #{self.manager_sign_username}'s profile to be able to sign.")
            else  # SIGN!
              self.manager_signer = manager
              self.manager_sign_hash = Digest::SHA1.hexdigest("--#{manager.social_security_number}--#{self.instance.created_at}--")
              self.manager_sign_date = Time.now
              self.save_status = self.save_status.to_s + " Store Manager signature accepted. Reload this page to see the digital fingerprint."
            end
          else
            errors.add(:store_manager, "signature must be a store manager.") if !manager.nil? && !manager.is_store_admin?
          end
        else
          errors.add(:store_manager, "could not be validated. Please check your username and password and try again.") if !self.manager_sign_username.blank?
        end
      # end

      errors.add(:employee_sign_username, "can't be blank") if self.instance.status.as_status.number > 1 && employee_sign_username.blank? && !self.is_signed?

      # if self.class.find(self.id).employee_signed?
      #   errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.employee_sign_username.blank?
      # else
        if employee = User.authenticate(self.employee_sign_username, self.employee_sign_password, Thread.current['user'].domain)
          if employee.social_security_number.blank?
            errors.add(:social_security_number, "needs to be set in #{self.employee_sign_username}'s profile to be able to sign.")
          else  # SIGN!
            self.employee_signer = employee
            self.employee_sign_hash = Digest::SHA1.hexdigest("--#{employee.social_security_number}--#{self.instance.created_at}--")
            self.employee_sign_date = Time.now
            self.save_status = self.save_status.to_s + " Employee signature accepted. Reload this page to see the digital fingerprint."
          end
        else
          errors.add(:store_employee, "could not be validated. Please check your username and password and try again.") if !self.employee_sign_username.blank?
        end
      # end

      # if self.class.find(self.id).employee_signed?
      #   errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.employee_sign_username.blank?
      # else
      #   employee = User.authenticate(self.employee_sign_username, self.employee_sign_password, Thread.current['user'].domain)
      #   errors.add(:employee, "could not be validated. Please check your username and password and try again.") if !employee && !self.employee_sign_username.blank?
      #   errors.add(:social_security_number, "needs to be set in #{self.employee_sign_username}'s profile to be able to sign.") if !employee.nil? && employee.social_security_number.blank?
      # end
      
      # self.instance.status_number = 1 if ((!employee_signed? and employee.nil?) || (!manager_signed? and manager.nil?))
      errors.add_to_base("This form must first be signed before it can be submitted.") if self.instance.status_number > 1 && ((!employee_signed? and employee.nil?) || (!manager_signed? and manager.nil?))
# - - - - - - - - - OLD CODE - - -
      # if self.manager_signed?
      #   errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.manager_sign_username.blank?
      # else
      #   manager = User.authenticate(self.manager_sign_username, self.manager_sign_password, Thread.current['user'].domain)
      #   errors.add(:store_manager, "could not be validated. Please check your username and password and try again.") if !manager && !self.manager_sign_username.blank?
      #   errors.add(:store_manager, "signature must be a store manager.") if !manager.nil? && !manager.is_store_admin?
      #   errors.add(:social_security_number, "needs to be set in #{self.manager_sign_username}'s profile to be able to sign.") if !manager.nil? && manager.social_security_number.blank?
      # end
      # 
      # if self.employee_signed?
      #   errors.add_to_base("CANNOT re-sign this form once it is signed!") if !self.employee_sign_username.blank?
      # else
      #   employee = User.authenticate(self.employee_sign_username, self.employee_sign_password, Thread.current['user'].domain)
      #   errors.add(:employee, "could not be validated. Please check your username and password and try again.") if !employee && !self.employee_sign_username.blank?
      #   errors.add(:social_security_number, "needs to be set in #{self.employee_sign_username}'s profile to be able to sign.") if !employee.nil? && employee.social_security_number.blank?
      # end
      # 
      # errors.add_to_base("This form must first be signed before it can be submitted.") if self.instance.status_number > 1 && ((!employee_signed? and employee.nil?) || (!manager_signed? and manager.nil?))
    end

    # Grab the user who authenticated and store in self.digital_signature_hash a hash of the user's social-security number and self.created_at
    # def create_signature_hashes
    #   if !self.manager_sign_username.blank?
    #     manager = User.find_by_username_and_store_id(self.manager_sign_username, Thread.current['user'].store_id)
    #     self.manager_signer = manager
    #     self.manager_sign_hash = Digest::SHA1.hexdigest("--#{manager.social_security_number}--#{self.instance.created_at}--")
    #     self.manager_sign_date = Time.now
    #     self.save_status = self.save_status.to_s + " Store Manager signature accepted. Reload this page to see the digital fingerprint."
    #   end
    # 
    #   if !self.employee_sign_username.blank?
    #     employee = User.find_by_username_and_store_id(self.employee_sign_username, Thread.current['user'].store_id)
    #     self.employee_signer = employee
    #     self.employee_sign_hash = Digest::SHA1.hexdigest("--#{employee.social_security_number}--#{self.instance.created_at}--")
    #     self.employee_sign_date = Time.now
    #     self.save_status = self.save_status.to_s + " Employee signature accepted. Reload this page to see the digital fingerprint."
    #   end
    # end
end
