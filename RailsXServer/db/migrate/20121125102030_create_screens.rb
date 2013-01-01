class CreateScreens < ActiveRecord::Migration
  def change
    create_table :screens do |t|
      t.string     :url, null:false
      t.references :user

      t.datetime :last_cast
      t.integer  :total_viewer, default:0
      t.integer  :max_viewer, default:0
      t.integer  :total_time, default:0

      t.integer :state, default:0
      t.integer :current_time, default:0
      t.integer :current_total_viewer, default:0
      t.integer :current_max_viewer, default:0
      t.integer :current_viewer, default:0
      t.string  :title
      t.string  :color
      t.text    :vt100
      t.integer :pause_count, default:0
      t.timestamps
    end
    add_index :screens,:url,name:'by_url',unique:true
  end
end
