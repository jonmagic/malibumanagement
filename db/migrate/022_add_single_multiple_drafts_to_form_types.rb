class AddSingleMultipleDraftsToFormTypes < ActiveRecord::Migration
  def self.up
    add_column :form_types, :can_have_multiple_drafts, :boolean
  end

  def self.down
    remove_column :form_types, :can_have_multiple_drafts
  end
end
