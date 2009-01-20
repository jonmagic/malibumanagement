class CreateFormTypes < ActiveRecord::Migration
  def self.up
    create_table "form_types", :force => true do |t|
      t.column "friendly_name",            :string
      t.column "name",                     :string
      t.column "can_have_notes",           :boolean, :default => true
      t.column "can_have_multiple_drafts", :boolean, :default => true
      t.column "draftable",                :boolean, :default => true
      t.column "reeditable",               :boolean, :default => true
    end
  end

  def self.down
    drop_table :form_types
  end
end
