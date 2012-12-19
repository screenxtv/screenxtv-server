class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.text :email
      t.string :password_digest
      t.string :auth_key
      t.timestamps
    end
    add_index :screens,:name,name:'by_name',unique:true
    add_index :screens,:email,name:'by_email',unique:true
  end
end
