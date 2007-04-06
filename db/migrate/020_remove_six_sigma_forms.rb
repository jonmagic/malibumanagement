class RemoveSixSigmaForms < ActiveRecord::Migration
  def self.up
    drop_table :basic_forms
    execute 'DELETE FROM form_types WHERE name="BasicForm"'
    drop_table :second_forms
    execute 'DELETE FROM form_types WHERE name="SecondForm"'
    drop_table :account_setups
    execute 'DELETE FROM form_types WHERE name="AccountSetup"'
  end

  def self.down
    create_table :basic_forms
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes) VALUES("CMS-1500", "BasicForm", 1)'
    create_table :second_forms
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes) VALUES("CMS-1500", "SecondForm", 1)'
    create_table :account_setups
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes) VALUES("Account Setup", "AccountSetup", 1)'
  end
end
