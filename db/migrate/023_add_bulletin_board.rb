class AddBulletinBoard < ActiveRecord::Migration
  def self.up
    create_table "posts", :force => true do |t|
      t.column "author_id",        :integer
      t.column "title",            :string
      t.column "text",             :text
      t.column "created_at",       :datetime
      t.column "updated_at",       :datetime
      t.column "attachment",       :string
    end
  end

  def self.down
    drop_table :posts   
  end
end
