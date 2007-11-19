module GotoBilling
  module Formats
    # Lookup the format class from a mime type reference symbol. Example:
    #
    #   GotoBilling::Formats[:xml]  # => GotoBilling::Formats::XmlFormat
    #   GotoBilling::Formats[:json] # => GotoBilling::Formats::JsonFormat
    def self.[](mime_type_reference)
      GotoBilling::Formats.const_get(mime_type_reference.to_s.camelize + "Format")
    end
  end
end

require 'goto_billing/formats/xml_format'
