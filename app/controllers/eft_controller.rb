class EftController < ApplicationController
  layout 'admin'
  before_filter :get_batch

  def regenerate_batch
    restrict('allow only admins') or begin
      @batch.update_attributes(EftBatch.new(:for_month => @for_month).attributes)
      redirect_to eft_path(:for_month => @for_month)
    end
  end
  
  def view_batch_stats
    restrict('allow only admins')
  end
  
  def submit_batch
    restrict('allow only admins') or begin
      @batch.update_attributes(:eft_ready => true)
      # Return a nice "Yeah it's submitted" indication .. then show "Batch Submitted, ## Payments pending" instead of Submit Batch link.
      # flash[:notice] = "Batch has been submitted for processing."
      # Should use my jquery message thingy
      redirect_to eft_path(:for_month => @for_month)
    end
  end

  def download_csv
    send_file 'EFT/' + @for_month + '/' + params[:file] + '.csv', :type => Mime::Type.lookup_by_extension('csv').to_str, :disposition => 'inline'
  end
  
  def location_csv
    stream_csv(params[:location] + '_payments.csv') do |csv|
      CSV::Reader.parse(File.open(@batch.eft_path+'payment.csv', 'rb')) do |row|
        if headers
          headers = false
          next
        end
        goto = GotoTransaction.new_from_csv_row(row)
        csv << goto.to_managers_a if goto.location == params[:location]
      end
    end
  end

  private
    def stream_csv(filename)
      require 'fastercsv'
      if request.env['HTTP_USER_AGENT'] =~ /msie/i
        headers['Pragma'] = 'public'
        headers["Content-type"] = "text/plain" 
        headers['Cache-Control'] = 'no-cache, must-revalidate, post-check=0, pre-check=0'
        headers['Content-Disposition'] = "attachment; filename=\"#{filename}\"" 
        headers['Expires'] = "0" 
      else
        headers["Content-Type"] ||= 'text/csv'
        headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" 
      end
      render :text => Proc.new { |response, output|
        csv = FasterCSV.new(output, :row_sep => "\r\n")
        yield csv
      }
    end

    def get_batch
      @for_month = params[:for_month]
      @batch = @for_month.nil? ? EftBatch.find(:first, :order => 'id DESC') : EftBatch.find_or_create_by_for_month(@for_month) # Get last-created EftBatch
      # If there are no batches, create one for the next payment month.
      if @batch.nil?
        @for_month = (Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
        @batch = EftBatch.find_or_create_by_for_month(@for_month)
      elsif !params[:for_month]
        # If last batch has not been submitted yet, use it.
        if @batch.submitted_at.blank?
          @for_month = @batch.for_month
        else # If last batch has been submitted, create the next one.
          time = Time.parse(@batch.for_month)
          @for_month = (time.strftime("%Y").to_i + time.strftime("%m").to_i/12).to_i.to_s + '/' + time.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
          @batch = EftBatch.find_or_create_by_for_month(@for_month) if @batch.nil? || !@batch.submitted_at.blank?
        end
      end
      # logger.info(@for_month)
    end
end

class Fixnum
  # Adds one number to another, but rolls over to the beginning of the range whenever it hits the top of the range.
  def cyclical_add(addend, cycle_range)
    raise ArgumentError, "#{self} is not within range #{cycle_range}!" if !cycle_range.include?(self)
    while(self+addend > cycle_range.last)
      addend -= cycle_range.last-cycle_range.first+1
    end
    return self+addend
  end
end
