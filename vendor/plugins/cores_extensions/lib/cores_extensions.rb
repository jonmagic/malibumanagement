module CoresExtensions
  StepLevel = [0]
  def step(description,options={},&block)
    CoresExtensions::StepLevel[0] = CoresExtensions::StepLevel[0]+1
    logit = lambda {|txt|
      begin
        puts(("  "*(CoresExtensions::StepLevel[0]-1)).to_s + txt.to_s)
        ActionController::Base.logger.info(("  "*(CoresExtensions::StepLevel[0]-1)).to_s + txt.to_s)
      rescue => f
        puts f
      end
    }
    logit.call(description+'...')
    begin
      v = yield if block_given?
      logit.call(description+" -> Done.")
      CoresExtensions::StepLevel[0] = CoresExtensions::StepLevel[0]-1
      return v
    rescue => e
      logit.call("["+description+"] Caused Errors: {#{e}}\n#{caller[0..4].join("\n")}")
      CoresExtensions::StepLevel[0] = CoresExtensions::StepLevel[0]-1
      if options[:retry].is_a?(Numeric) && options[:retry] > 0
        begin
          puts(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "Retrying...")
          ActionController::Base.logger.info(("  "*(CoresExtensions::StepLevel[0]+1)).to_s + "Retrying...")
        rescue => f
          puts f
        end
        step(description,options.merge(:retry => options[:retry] - 1),&block)
      else
        return false
      end
    end
  end

  def debug_step(msg, id=nil)
    $DEBUG_CONTINUE ||= {}
    unless $DEBUG_CONTINUE[id]
      STDOUT << msg
      STDOUT << " (YA = Continue to end)"
      STDOUT.flush
      yn = STDIN.gets
      $DEBUG_CONTINUE[id] = true if yn.chomp == 'YA'
    end
  end

  def confirm_step(msg, cid=nil)
    cid ||= msg
    $CONFIRM_CONTINUE ||= {}
    yn = if $CONFIRM_CONTINUE[cid]
      $CONFIRM_CONTINUE[cid]
    else
      STDOUT << msg
      STDOUT << " (Y=Continue, S=Skip one, YA=Continue to end, SA=Skip all)"
      STDOUT.flush
      STDIN.gets.chomp
    end
    return case yn
    when 'Y'
      yield
    when 'YA'
      $CONFIRM_CONTINUE[cid] = 'Y'
      yield
    when 'S'
      nil
    when 'SA'
      $CONFIRM_CONTINUE[cid] = 'N'
      nil
    end
  end

  def with(*objects)
    yield  *objects
    return *objects
  end
end
self.extend CoresExtensions
Kernel.send :include, CoresExtensions

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
    self.to_s.to_csv
  end
end

class Array
  def to_csv
    map {|v| v.to_csv}.join(',')
  end
end

class Float
  def to_csv
    self.to_s.to_csv
  end
end

class String
  def to_csv
    # "'"+self+"'"
    self.gsub(/,/, '')
  end
end

class NilClass
  def to_csv
    nil
  end
end
