last_daily_batch = Time.yesterday
begin
  if batch = EftBatch.find(:first, :conditions => ['regenerate_now IS NOT NULL AND regenerate_now != ""'])
    location = batch.regenerate_now == 'all' ? nil : batch.regenerate_now
    batch.generate(location)
  end
  if Time.now.hour > 23 # after 11pm -- should catch this and should happen only once.
    EftBatch.find_or_create_by_for_month((Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s).generate
    last_daily_batch = Time.now
  end
end while sleep(60) # Wait one minutes between checks.
