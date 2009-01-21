class WarningsReeditable < ActiveRecord::Migration
  def self.up
    execute 'UPDATE form_types SET reeditable=1 WHERE name="WrittenWarning" OR name="VerbalWarning"'
  end
  
  def self.down
    execute 'UPDATE form_types SET reeditable=0 WHERE name="WrittenWarning" OR name="VerbalWarning"'
  end
end
