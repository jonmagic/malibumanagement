$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

unless defined?(ActiveSupport)
  begin
    $:.unshift(File.dirname(__FILE__) + "/../../vendor/rails/activesupport/lib")  
    require 'active_support'  
  rescue LoadError
    require 'rubygems'
    gem 'activesupport'
  end
end

require 'goto_billing/support'
require 'goto_billing/formats'
require 'goto_billing/base'
require 'goto_billing/validations'

module GotoBilling
  Base.class_eval do
    include Validations
  end
end
