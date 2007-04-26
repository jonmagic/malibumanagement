module NumberFieldHelper
  def color_amount(amount)
    amount = 0 if amount.nil?
    amount.to_f > 0 ? "<span class='number_positive'>#{amount}</span>" : (amount.to_f == 0 ? "<span class='number_zero'>#{amount}</span>" : "<span class='number_negative'>#{amount}</span>")
  end
end
module ActionView
  module Helpers
    module FormHelper
      def number_field(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag(options.merge({:onkeypress => 'return numbersonly(event)'}))
      end
    end
    module FormTagHelper
      def number_field_tag(name, value = nil, options = {})
        tag :input, { "type" => "text", "name" => name, "id" => name, "value" => value, "onkeypress" => 'return numbersonly(event)' }.update(options.stringify_keys)
      end
    end
    class FormBuilder
      def number_field(method, options = {})
        @template.number_field(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end
