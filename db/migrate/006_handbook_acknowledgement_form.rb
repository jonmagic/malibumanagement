class HandbookAcknowledgementForm < ActiveRecord::Migration
  def self.up
    create_table "handbook_acknowledgements", :force => true do |t|
      t.column :digital_signature_id,   :integer
      t.column :digital_signature_hash, :string
      t.column :digital_signature_date, :datetime
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Handbook Acknowledgement", "HandbookAcknowledgement", 0, 0, 0, 0)'
    #****
  end

  def self.down
    drop_table :handbook_acknowledgements
    execute 'DELETE FROM form_types WHERE name="HandbookAcknowledgement"'
    execute 'DELETE FROM form_instances WHERE data_type="HandbookAcknowledgement"'
  end
end
