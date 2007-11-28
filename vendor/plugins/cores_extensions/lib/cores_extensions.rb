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

def with(*objects)
  yield  *objects
  return *objects
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

  def to_csv
    self.to_s
  end
end

class Float
  def to_csv
    self.to_s
  end
end

class String
  def to_csv
    "'"+self+"'"
  end
end

class NilClass
  def to_csv
    nil
  end
end
