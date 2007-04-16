class LogsController < ApplicationController
  layout 'logs'

  def form_logs
    @form = FormInstance.find_by_id(params[:form_id])
    @logs = @form.logs
    @logs.push(@form.data.logs)
    @readable_logs = Log.readable_logs_for_FormInstances(@logs)
  end

  def history
    @logs = Log.find(:all, :order => :created_at, :limit => 50)
  end

end
