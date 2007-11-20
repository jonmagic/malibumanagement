begin
  EftBatch.find(:first, :conditions => ['regenerate_now IS NOT NULL']).each do |batch|
    location = batch.regenerate_now == 'all' ? nil : batch.regenerate_now
    batch.regenerate(location)
  end
end while sleep(60) # Wait two minutes between checks.
