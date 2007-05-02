require 'net/http'
require 'uri'
require 'time'

module CalendarReader

# Daniel's public gcal: http://www.google.com/calendar/ical/dcparker%40gmail.com/public/basic.ics
# include CalendarReader
# g = Calendar.new('http://www.google.com/calendar/ical/dcparker%40gmail.com/public/basic.ics')
  class Calendar
    attr_accessor :url, :ical, :xml, :product_id, :version, :scale, :method, :time_zone_name, :time_zone_offset, :events

    def initialize(cal_url=nil)
      if cal_url
        self.url = cal_url
        self.parse!
      end
    end

    def add_event(event)
      self.events ||= []
      self.events.push(event)
    end

    def self.parse(cal_url)
      self.new(cal_url)
    end

    def parse!
      self.url =~ /\.ics(?:\?.+)?$/ ? self.parse_from_ical! : self.parse_from_xml!
    end
    def parse
      self.dup.parse!
    end

    def parse_from_xml!
      return false # THIS IS NOT IMPLEMENTED YET!!
    end
    def parse_from_xml
      self.dup.parse_from_xml
    end

    def parse_from_ical!
      self.ical = ICal.new(self.calendar_raw_data)
      self.version  = self.ical.hash['VCALENDAR']['VERSION']
      self.scale    = self.ical.hash['VCALENDAR']['CALSCALE']
      self.method   = self.ical.hash['VCALENDAR']['METHOD']
      self.product_id = self.ical.hash['VCALENDAR']['PRODID']
      self.time_zone_name = self.ical.hash['VCALENDAR']['VTIMEZONE']['TZID']
      self.time_zone_offset = self.ical.hash['VCALENDAR']['VTIMEZONE']['STANDARD']['TZOFFSETTO']
      self.ical.hash['VCALENDAR']['VEVENT'].each do |e|
        # DTSTART;VALUE=DATE # format of yyyymmdd
        # DTSTART;TZID=America/Chicago # format of yyyymmddThhmmss
        # DTEND;VALUE=DATE # format of yyyymmdd
        # DTEND;TZID=America/Chicago # format of yyyymmddThhmmss
        # DTSTAMP # format of yyyymmddThhmmssZ - today's date and time!
        # TRANSP # disreguard - transparency: opaque
        # LOCATION # location string
        # LAST-MODIFIED # format of yyyymmddThhmmssZ
        # SEQUENCE # integer - not sure what it is
        # UID # characters@google.com - not sure what it's for, but they're all unique
        # CATEGORIES # in gcal, all = 'http'
        # SUMMARY # summary/title string
        # CLASS # in gcal = PUBLIC or PRIVATE?
        # STATUS # in gcal = CONFIRMED
        # ORGANIZER;CN=Moody Campus # in gcal, all = MAILTO
        # CREATED # format of yyyymmddThhmmssZ
        # DESCRIPTION # description string
        # ATTENDEE;CUTYPE=GROUP;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;CN=Moody Campu\ns;X-NUM-GUESTS=0 # so far always nil
        # COMMENT;X-COMMENTER=MAILTO # someone's email address, perhaps if they commented on the event.
        # RRULE # Recurrance Rule - string like 'FREQ=WEEKLY'
        st = e["DTSTART;TZID=#{self.time_zone_name}"] || "#{e['DTSTART;VALUE=DATE']}T000000"
        et = e["DTEND;TZID=#{self.time_zone_name}"] || "#{e['DTEND;VALUE=DATE']}T000000"
        self.add_event(Event.new(
          :start_time => Time.gcalschema("#{st}Z"),
          :end_time => Time.gcalschema("#{et}Z"),
          :location => e['LOCATION'],
          :created_at => Time.gcalschema(e['CREATED']),
          :updated_at => Time.gcalschema(e['LAST-MODIFIED']),
          :summary => e['SUMMARY'],
          :description => e['DESCRIPTION'],
          :recurrance_rule => e['RRULE']
        ))
      end
    end
    def parse_from_ical
      self.dup.parse_from_ical
    end

    def source_format
      self.ical ? 'ical' : (self.xml ? 'xml' : nil)
    end

    def future_events
      future = []
      self.events.each do |event|
        future.push(event) if event.start_time > Time.now
      end
      future
    end

    def past_events
      past = []
      self.events.each do |event|
        past.push(event) if event.start_time < Time.now
      end
      past
    end

    def events_in_range(start_time, end_time)
      es = []
      self.events.each do |event|
        es.push(event) if event.start_time < end_time && event.end_time > start_time
      end
      es
    end

    def calendar_raw_data
      # Net::HTTP::Proxy(host, port, user, pass).start('www.google.com', 80) do |http|
      Net::HTTP.start('www.google.com', 80) do |http|
        response, data = http.get(self.url)
        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return data
        else
          response.error!
        end
      end
    end

    class Event
      attr_accessor :start_time, :end_time, :location, :created_at, :updated_at, :summary, :description, :recurrance_rule
      def initialize(attributes={})
        attributes.each do |key, value|
          self.send("#{key.to_s}=", value)
        end
      end
    end
  end

  class ICal
    attr_accessor :hash, :raw
    def initialize(ical_data)
puts 'Beginning to parse data...'
      self.raw  = ical_data
      self.hash = self.parse_ical_data(self.raw)
    end

    def parse_ical_data(data)
      data.gsub!(/\\\n/, "\\n")
      data.gsub!(/[\n\r]+ /, "\\n")
      lines = data.split(/[\n\r]+/)
      structure = [{}]
      keys_path = []
      last_is_array = false
      lines.each do |line|
        line.gsub!(/\\n/, "\n")        
        pair = line.split(':')
        name = pair.shift
        value = pair.join(':')
        case name
        when 'BEGIN'  #Begin Section
          if structure[-1].has_key?(value)
            if structure[-1][value].kind_of?(Array)
              structure[-1][value].push({})
              last_is_array = true
            else
              structure[-1][value] = [structure[-1][value], {}]
              last_is_array = true
            end
          else
            structure[-1][value] = {}
          end
          keys_path.push(value)
          structure.push({})
        when 'END'    #End Section
          if last_is_array
            structure[-2][keys_path.pop][-1] = structure.pop
            last_is_array = false
          else
            structure[-2][keys_path.pop] = structure.pop
          end
        else          #Within last Section
          structure[-1][name] = value
        end
      end
      structure[0]
    end
  end

end

class Time
  def self.gcalschema(tzid) #We may not be handling Time Zones in the best way...
     if tzid =~ /(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)Z/ # yyyymmddThhmmss
       Time.xmlschema("#{$1}-#{$2}-#{$3}T#{$4}:#{$5}:#{$6}")
     else
       return nil
     end
  end
end
