class CreateOauths < ActiveRecord::Migration
  def change
    create_table :oauths do |t|
      t.references :user
      t.string :provider
      t.string :uid
      t.string :token
      t.string :secret
      t.string :name
      t.string :icon
      t.string :display_name
      t.timestamps
    end
    add_index :oauths, :user_id
    add_index :oauths, [:provider, :uid], unique:true
  end
end
