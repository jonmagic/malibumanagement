module ActionView
  module Helpers
    class InstanceTag
      def to_date_picker_field_tag(method, options = {})
        options = DEFAULT_TEXT_AREA_OPTIONS.merge(options.stringify_keys)
        add_default_name_and_id(options)
        value = options.delete('value') || value_before_type_cast(object)
        display_value = value.respond_to?(:strftime) ? value.strftime('%b %d, %Y') : value.to_s
        display_value = '[ choose date ]' if display_value.blank?
        value = Time.parse(value) unless value.respond_to?(:strftime)

        add_default_name_and_id(options)

        out = tag('input', 'name' => options["name"], 'id' => options["id"], 'type' => 'hidden', 'value' => value.strftime('%Y-%m-%d'), 'onchange' => options['onchange'])
        out << content_tag('a', display_value, :href => '#',
            :id => "_#{options['id']}_link", :class => '_date_picker_link',
            :onclick => options['display_as'] ? "DatePicker.toggle(this.previousSibling, this, "+options['display_as']+"); return false;" : "DatePicker.toggle(this.previousSibling, this); return false;"
        )
        if object.respond_to?(:errors) and object.errors.on(method) then
          ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
        else
          out
        end
      end
    end

    class FormBuilder
      def date_picker_field(method, options = {})
        @template.date_picker_field(@object_name, method, options.merge(:object => @object))
      end

      def number_field(method, options = {})
        @template.number_field(@object_name, method, options.merge(:object => @object))
      end

      def currency_field(method, options = {})
        @template.currency_field(@object_name, method, options.merge(:object => @object))
        "Currency field!"
      end

      def values_toggle(method, options = {})
        @template.values_toggle(@object_name, method, options.merge(:object => @object))
      end

      def drop_down(method, options = {})
        @template.drop_down(@object_name, method, options.merge(:object => @object))
      end

      def editable_drop_down(method, options = {})
        @template.editable_drop_down(@object_name, method, options.merge(:object => @object))
      end
      alias :combo_box :editable_drop_down

      def social_security_field(method, options = {})
        @template.social_security_field(@object_name, method, options.merge(:object => @object))
      end

      def address_field(method, options = {})
        @template.address_field(@object_name, method, options.merge(:object => @object))
      end

      def telephone_field(method, options = {})
        @template.telephone_field(@object_name, method, options.merge(:object => @object))
      end
    end

    module PrototypeHelper
      def build_observer(klass, name, options = {})
        if options[:with] && !options[:with].include?("=")
          options[:with] = "'#{options[:with]}=' + value"
        else
          options[:with] ||= 'value' if options[:update]
        end

        callback = options[:function] || remote_function(options)
        javascript = options[:assigns] + " = " if options[:assigns]
        javascript = '(' unless options[:assigns]
        javascript << "new #{klass}('#{name}', "
        javascript << "#{options[:frequency]}, " if options[:frequency]
        javascript << "function(element, value) {"
        javascript << "#{callback}}"
        javascript << ", '#{options[:on]}'" if options[:on]
        javascript << "); " + options[:assigns] + ".lastValue = ''" if options[:assigns]
        javascript << ")).lastValue = '';" unless options[:assigns]
        javascript_tag(javascript)
      end
    end

    module FormHelper
      def date_picker_field(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_date_picker_field_tag(method, options)
      end

#f.address_field(:address_line_1 => [:address, @values.responsible_address], :city => [:city, @values.responsible_city], :state => [:state, @values.responsible_state], :zip => [:zipcode, @values.responsible_zipcode])
      def address_field(object_name, method, options = {})
        # old_object = @object
        # @object = options[:object] if options[:object]
        mapping = {:address_line_1 => options.delete(:address_line_1) || :address, :address_line_2 => options.delete(:address_line_2) || :address_line_2, :city => options.delete(:city) || :city, :state => options.delete(:state) || :state, :zip => options.delete(:zip) || :zip}
        out = "<span>"
        out << self.text_field(object_name, mapping[:address_line_1], :value => self.class.value_before_type_cast(object, mapping[:address_line_1]), :size => 30) << "<br />" if mapping[:address_line_1].length > 1

        out << self.text_field(object_name, mapping[:address_line_2], :value => self.class.value_before_type_cast(object, mapping[:address_line_2]), :size => 30) << "<br />" if mapping[:address_line_2].length > 1

        out << self.text_field(object_name, mapping[:city], :value => self.class.value_before_type_cast(object, mapping[:city]), :size => 13) << ", &nbsp; " if mapping[:city].length > 1

        out << self.drop_down(object_name, mapping[:state], :value => self.class.value_before_type_cast(object, mapping[:state]), :values => ["AL -Alabama", "AK -Alaska", "AZ -Arizona", "AR -Arkansas", "CA -California", "CO -Colorado", "CT -Connecticut", "DE -Delaware", "FL -Florida", "GA -Georgia", "HI -Hawaii", "ID -Idaho", "IL -Illinois", "IN -Indiana", "IA -Iowa", "KS -Kansas", "KY -Kentucky", "LA -Louisiana", "ME -Maine", "MD -Maryland", "MA -Massachusetts", "MI -Michigan", "MN -Minnesota", "MS -Mississippi", "MO -Missouri", "MT -Montana", "NE -Nebraska", "NV -Nevada", "NH -New Hampshire", "NJ -New Jersey", "NM -New Mexico", "NY -York New York", "NC -North Carolina", "ND -North Dakota", "OH -Ohio", "OK -Oklahoma", "OR -Oregon", "PA -Pennsylvania", "RI -Rhode Island", "SC -South Carolina", "SD -South Dakota", "TN -Tennessee", "TX -Texas", "UT -Utah", "VT -Vermont", "VA -Virginia", "WA -Washington", "WV -West Virginia", "WI -Wisconsin", "WY -Wyoming"], :size => 2) << " &nbsp;" if mapping[:state].length > 1

        out << self.text_field(object_name, mapping[:zip], :value => self.class.value_before_type_cast(object, mapping[:zip]), :size => 6, :maxlength => 10) << "</span>" if mapping[:zip].length > 1

        # @object = old_object

        out
      end

      def number_field(object_name, method, options = {})
        options["class"] = (options["class"] ? options['class'] + ' ' : '') + method.to_s + '_field'
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag('text', options.merge({:onkeypress => 'return numbersonly(event)'}))
      end

      def currency_field(object_name, method, options = {})
        options["class"] = (options["class"] ? options['class'] + ' ' : '') + method.to_s + '_field'
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag('text', options.merge({:onkeypress => 'return currencycorrect(event)'}))
      end

      def telephone_field(object_name, method, options = {})
        options["class"] = (options["class"] ? options['class'] + ' ' : '') + method.to_s + '_field'
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag('text', options.merge({:onkeypress => 'return telephonenumbercorrect(event)'}))
      end

      def social_security_field(object_name, method, options = {})
        options["class"] = (options["class"] ? options['class'] + ' ' : '') + method.to_s + '_field'
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_input_field_tag('text', options.merge({:maxlength => 9, :onkeypress => 'return socialsecuritycorrect(event)'}))
      end

      def drop_down(object_name, method, options = {})
        values = options.delete(:values)
        labels = options.delete(:labels)
        labels ||= values
        options[:value] = values[values.index(options[:value]) || 0]
        options[:size] = (((options[:size]+3)*0.62)+1).to_i if options[:size]

        @drop_down_values = Struct.new(:the_value).new(options[:value])
        it = InstanceTag.new(:drop_down_values, :the_value, self, nil, options.delete(:object))
        options['id'] = "#{object_name.gsub(/[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{method.to_s.dup}";
        options['name'] = "#{object_name}[#{method.to_s.dup}]"
        it.send(:add_default_name_and_id, options)
        it.to_select_tag(values, options, {:name => options['name'], :id => options['id'], :style => "width:#{options[:size]}em;"})
      end

      def editable_drop_down(object_name, method, options = {})
        values = options.delete(:values)
        labels = options.delete(:labels)
        labels ||= values
        options[:value] = values[values.index(options[:value]) || 0]
        input_size ||= labels.longest_item_size
        input_size -= 1
        select_size = (((input_size+3)*0.62)+1).to_i

        @drop_down_values = Struct.new(:the_value).new(options[:value])
        it = InstanceTag.new(:drop_down_values, :the_value, self, nil, options.delete(:object))
        options['id'] = "#{object_name.gsub(/[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{method.to_s.dup}_dropdown"
        options['name'] = "#{object_name}[#{method.to_s.dup}]_dropdown"
        input_id = "#{object_name.gsub(/[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{method.to_s.dup}"
        input_name = "#{object_name}[#{method.to_s.dup}]"
        it.send(:add_default_name_and_id, options)
        out = javascript_tag('var clicked_the_dropdown = false;')
        out << it.to_select_tag(values, options, {:name => options['name'], :id => options['id'], :style => "width:#{select_size}em;", :onchange => "$('#{input_id}').value = this.value"})
        options['size'] = input_size
        options['id'] = input_id
        options['name'] = input_name
        options["class"] = (options["class"] ? options['class'] + ' ' : '') + method.to_s + '_field'
        out << it.to_input_field_tag("text", options.merge({:style => "position:relative; left:-#{select_size}em;"}))
        out
      end
      alias :combo_box :editable_drop_down

      def values_toggle(object_name, method, options = {})
        # Hidden field updated by a clickable link that rotates through the values.
        values = options.delete(:values)
        labels = options.delete(:labels)
        labels ||= values
        options[:value] = values[values.index(options[:value]) || 0]

        it = InstanceTag.new(object_name, method, self, nil, options.delete(:object))
        it.send(:add_default_name_and_id, options)
        out = it.to_input_field_tag("hidden", options)
        if !values.blank?
          out << "<a id='#{options["id"]}_link' href='javascript:void(0)' onclick='values_toggle(this, \"#{options["id"]}\", [" + values.map {|a| "\"#{a}\""}.join(', ') +"], [" + labels.map {|a| "\"#{a}\""}.join(', ') + "])'>#{labels[values.index(options[:value]) || 0]}</a>"
        else
          out << "<span>#{options[:value]}</span>" #Preferrably this will never happen.
        end
        out
      end
    end

    module FormTagHelper
      def number_field_tag(name, value = nil, options = {})
        tag :input, { "type" => "text", "name" => name, "id" => name, "value" => value, "onkeypress" => 'return numbersonly(event)' }.update(options.stringify_keys)
      end

      def currency_field_tag(name, value = nil, options = {})
        tag :input, { "type" => "text", "name" => name, "id" => name, "value" => value, "onkeypress" => 'return currencycorrect(event)' }.update(options.stringify_keys)
      end

      def date_picker_tag(name, value = nil, options = {})
        display_value = value.respond_to?(:strftime) ? value.strftime('%b %d, %Y') : value.to_s
        display_value = '[ choose date ]' if display_value.blank?
        value = Time.parse(value) unless value.respond_to?(:strftime)

        out = hidden_field_tag(name, value.strftime('%Y-%m-%d'))
        out << content_tag('a', display_value, :href => '#',
            :id => "_#{name}_link", :class => '_date_picker_link',
            :onclick => options['display_as'] ? "DatePicker.toggle(this.previousSibling, this, "+options['display_as']+"); return false;" : "DatePicker.toggle(this.previousSibling, this); return false;")
        out
      end
    end
  end
end
module ApplicationHelper
  def display_address(mapping)
    "<span>#{mapping[:address_line_1]}<br />#{mapping[:city]}, #{mapping[:state]} #{mapping[:zip]}</span>"
  end
  def color_amount(amount)
    amount = 0 if amount.nil?
    amount.to_f > 0 ? "<span class='number_positive'>#{amount}</span>" : (amount.to_f == 0 ? "<span class='number_zero'>#{amount}</span>" : "<span class='number_negative'>#{amount}</span>")
  end
end
class Array
  def longest_item_size
    self.sort {|b,a| a.length <=> b.length}[0].length
  end
end
class Integer < Numeric
  def floor_at(val)
    self < val ? val : self
  end
end
