class HandbookAcknowledgementForm < ActiveRecord::Migration
  def self.up
    create_table "handbook_acknowledgements", :force => true do |t|
      t.column "digital_signature_id",   :integer
      t.column "digital_signature_hash", :string
    end
  end

  def self.down
    drop_table :handbook_acknowledgements
  end
end