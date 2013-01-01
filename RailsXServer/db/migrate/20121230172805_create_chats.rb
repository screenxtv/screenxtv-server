class CreateChats < ActiveRecord::Migration
  def change
    create_table :chats do |t|
      t.references :screen, null:false
      
      t.string :name
      t.string :icon
      t.text :message, null:false

      t.timestamps
    end
  end
end
