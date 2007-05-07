require 'net/http'
require 'uri'
require 'time'

class TimeRange < Time
  attr_accessor :length
  def initialize(seconds)
    self.length = seconds
  end
  
  def from(time)
    self.set_start(time)
  end
  def from_now
    self.from(Time.now)
  end
  def set_start(time)
    AnchoredTimeRange.new(self.length, time)
  end
  def set_end(time)
    AnchoredTimeRange.new(self.length, time+self.length)
  end
end
class AnchoredTimeRange
  attr_accessor :start_time, :end_time, :length, :tied_events
  def initialize(length, start_time=Time.now)
    self.start_time = start_time
    self.length = length
    self.end_time = start_time+length
  end

  def set_start(time)
    self.start_time = time
    self
  end
  def set_end(time)
    self.end_time = time
    self
  end
  def weeks(begin_with_week=true)
    weeks = []
    if !begin_with_week
      thestart  = self.start_time.beginning_of_day
      theend    = self.start_time.beginning_of_day + ((self.end_time.beginning_of_day - self.start_time.beginning_of_day) / 1.week).ceil.weeks
    else
      thestart  = self.start_time.beginning_of_week
      theend    = self.end_time.beginning_of_week
      theend += 1.week if theend < self.end_time
    end
    ((theend - thestart)/1.week).ceil.times do |which_week|
      weeks.push(AnchoredWeek.new(thestart + which_week * 1.week).with_events(self.tied_events))
    end
    weeks
  end

# include CalendarReader
# @cal = Calendar.new('https://www.google.com/calendar/ical/yanno.org_lf810kkm8475qm1p5c1ncmilec%40group.calendar.google.com/private-28518e4e7f49d0470d59ba10047ce78b/basic.ics')
# 2.calendar_weeks.from_now.with_events(@cal)
# 2.calendar_weeks.from_now.with_events(@cal).weeks.collect {|w| w.start_time}
  def days
    days = []
    thestart  = self.start_time.beginning_of_day
    theend    = self.end_time.beginning_of_day
    theend += 1.day if theend < self.end_time
    ((theend - thestart)/1.day).ceil.times do |which_day|
      days.push(AnchoredDay.new(thestart + which_day * 1.day).with_events(self.tied_events))
    end
    days
  end
  def with_events(calendar)
    self.tied_events = calendar
    self
  end

  def events
    self.tied_events.events_in_range(self.start_time, self.end_time)
  end

  class AnchoredWeek < AnchoredTimeRange
    @@length = 1.week-1

    def initialize(start_time)
      super(@@length, start_time)
    end
  end
  class AnchoredDay < AnchoredTimeRange
    @@length = 1.day-1

    def initialize(start_time)
      super(@@length, start_time)
    end

    def name
      self.start_time.strftime("%A")
    end
  end
end

class Fixnum < Integer
  def calendar_weeks
    TimeRange.new(self.weeks)
  end
  def calendar_week
    self.calendar_weeks
  end

  def calendar_days
    TimeRange.new(self.days)
  end
  def calendar_day
    self.calendar_days
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

  def humanize_time
    self.strftime("%M").to_i > 0 ? self.strftime("#{self.strftime("%I").to_i.to_s}:%M%p").downcase : self.strftime("#{self.strftime("%I").to_i.to_s}%p").downcase
  end
  def humanize_date(length_profile='medium') #There may be decent reason to change how this works entirely...
    case length_profile
    when 'abbr' || 'abbreviated'
      self.strftime("%m/%d/%y")
    when 'short'
      self.strftime("%b #{self.strftime("%d").to_i.to_s}")
    when 'medium'
      self.strftime("%B #{self.strftime("%d").to_i.to_s}")
    when 'long'
      self.strftime("%B #{self.strftime("%d").to_i.to_s} %Y")
    end
  end
  def humanize_date_time
    self.humanize_date + ' ' + self.humanize_time
  end
end

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

    def add_event(event, sortit=true)
      self.events ||= []
      self.events << event
      @events.sort! {|a,b| a.start_time <=> b.start_time } if sortit
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
        ), false) # (disable sorting until done)
        @events.sort! {|a,b| a.start_time <=> b.start_time }
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
    
    # class Week
    #   attr_accessor :time_range
    #   @@range = TimeRange.new(1.week).freeze
    #   def initialize
    #     self.time_range = @@range
    #     self.extend(TimeRange)
    #   end
    # end
    # class Day
    #   attr_accessor :time_range
    #   @@range = TimeRange.new(1.day).freeze
    #   def initialize
    #     self.time_range = @@range
    #     self.extend(TimeRange)
    #   end
    # end
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
