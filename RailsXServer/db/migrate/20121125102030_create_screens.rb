class CreateScreens < ActiveRecord::Migration
  def change
    create_table :screens do |t|
      t.string :url
      t.references :user

      t.integer :total_viewer
      t.integer :max_viewer
      t.datetime :last_cast
      t.integer :total_time

      t.integer :state
      t.integer :current_time
      t.integer :current_total_viewer
      t.integer :current_max_viewer
      t.integer :current_viewer
      t.string :title
      t.string :color
      t.text :vt100
      t.integer :pause_count
      t.timestamps
    end
    add_index :screens,:url,name:'by_url',unique:true
  end
end
