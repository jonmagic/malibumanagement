class PatientsController < ApplicationController
  layout 'store'

  def live_search
    restrict('allow only store users') or begin
      @phrase = (request.raw_post || request.query_string).slice(/[^=]+/)
      if @phrase.blank?
        render(:file => 'forms/_new_form', :use_full_path => true)
      else
        @sqlphrase = "%" + @phrase.to_s + "%"
        @results = Patient.find(:all, :conditions => [ "store_id='#{current_user.store_id}' AND (account_number LIKE ? OR last_name LIKE ? OR first_name LIKE ? OR social_security_number LIKE ? OR telephone LIKE ?)", @sqlphrase, @sqlphrase, @sqlphrase, @sqlphrase, @sqlphrase])
        @search_entity = @results.length == 1 ? "Patient" : "Patients"
        render(:partial => 'shared/live_search_results', :locals => { :proxy_partial => @results.length == 0 ? 'forms/new_form' : 'live_search_results', :show_null_results => true })
      end
    end
  end
  
  def show
    restrict('allow only store users') or begin
      @patient = Patient.find_by_id(params[:id])
      return redirect_to store_dashboard_path() unless @patient.store_id == current_user.store_id
    end
  end

  # DELETE /patients/1
  # DELETE /patients/1.xml
  def destroy
    restrict('allow only store admins') or begin
      @patient = Patient.find_by_id(params[:id])
      return redirect_to store_dashboard_path() unless @patient.store_id == current_user.store_id
      @patient.destroy
      respond_to do |format|
        format.html { redirect_to store_dashboard_path() }
        format.xml  { head :ok }
      end
    end
  end

end
