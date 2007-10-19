module GotoBilling
  class Response < Hash
    def submitted?
      self['status'] != 'T'
    end
    
    def accepted?
      submitted? && (self['status'] == 'R' || self['status'] == 'G')
    end

    def paid_now?
      submitted? && self['status'] == 'G'
    end
    
    def declined?
      submitted? ? !accepted? : false
    end
    
    def retry?
      !submitted?
    end

    def duplicate?
      self['description'] =~ /^DUPLICATE_TRANSACTION_ALREADY_APPROVED/ ? true : false
    end
  end
end

class Hash
  def to_gb_response
    res = GotoBilling::Response.new
    self.each {|k,v| res[k] = v}
    res
  end
end
