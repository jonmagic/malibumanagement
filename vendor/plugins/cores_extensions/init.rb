def step(description)
  logit = lambda {|txt|
    begin
      puts txt
      ActionController::Base.logger.info(txt)
    rescue
    end
  }
  logit.call(description+'...')
  begin
    v = yield if block_given?
    logit.call(description+" -> Done.")
    return v
  rescue => e
    logit.call("["+description+"] Caused Errors: {#{e}}")
    return false
  end
end
