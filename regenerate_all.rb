EftBatch.find_or_create_by_for_month((Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s).update_attributes(:regenerate_now => 'all')
