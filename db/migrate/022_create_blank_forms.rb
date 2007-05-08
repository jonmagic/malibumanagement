class CreateBlankForms < ActiveRecord::Migration
  def self.up
    create_table :wildcard_forms do |t|
      t.column :description, :text
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Wildcard Form", "WildcardForm", 1, 1, 1, 1)'
  end

  def self.down
    drop_table :wildcard_forms
    execute 'DELETE FROM form_types WHERE name="WildcardForm"'
    execute 'DELETE FROM form_instances WHERE data_type="WildcardForm"'
  end
end
