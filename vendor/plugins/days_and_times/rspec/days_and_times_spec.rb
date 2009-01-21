require '../lib/days_and_times.rb'

describe Duration do
  it "should be backward-compatible with previous english time statements" do
    10.minutes.from_now.inspect.should eql((Time.now + 600).inspect)
    3.days.ago.inspect.should eql((Time.now - 3*24*60*60).inspect)
    # More english statements need to be written!!
  end

  it "should store a duration correctly in minutes if told to do so, even when created in seconds" do
    132.seconds.in_minutes.should be_is_a(Minutes)
    132.seconds.in_minutes.unit.should eql(60)
    132.seconds.in_minutes.length.to_s.should eql('2.2')
  end

  it "should add a duration properly to a Time object" do
    (Time.now+1.day).inspect.should eql((Time.now+86400).inspect)
  end
end