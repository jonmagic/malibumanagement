begin
  if batch = EftBatch.find(:first, :conditions => ['regenerate_now IS NOT NULL'])
    location = batch.regenerate_now == 'all' ? nil : batch.regenerate_now
    batch.generate(location)
  end
end while sleep(60) # Wait two minutes between checks.
