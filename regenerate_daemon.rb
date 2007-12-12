last_daily_batch = Time.yesterday
begin
  if batch = EftBatch.find(:first, :conditions => ['regenerate_now IS NOT NULL AND regenerate_now != ""'])
    location = batch.regenerate_now == 'all' ? nil : batch.regenerate_now
    batch.generate(location)
  end
end while sleep(60) # Wait one minutes between checks.
