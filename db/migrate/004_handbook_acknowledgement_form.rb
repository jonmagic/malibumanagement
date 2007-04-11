class HandbookAcknowledgementForm < ActiveRecord::Migration
  def self.up
    create_table "handbook_acknowledgements", :force => true do |t|
      t.column "digital_signature_id",   :integer
      t.column "digital_signature_hash", :string
    end
    #Also add this form type into the form_types table
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts) VALUES("Handbook Acknowledgement", "HandbookAcknowledgement", 1, 1)'
    #****
  end

  def self.down
    drop_table :handbook_acknowledgements
  end
end