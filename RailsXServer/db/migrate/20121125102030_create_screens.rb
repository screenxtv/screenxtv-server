class CreateScreens < ActiveRecord::Migration
  def change
    create_table :screens do |t|
      t.string :url
      t.string :title
      t.string :color
      t.string :vt100
      t.boolean :casting
      t.integer :viewer
      t.integer :pausecount
      t.timestamps
    end
    add_index :screens,:url,name:'by_url',unique:true
  end
end
