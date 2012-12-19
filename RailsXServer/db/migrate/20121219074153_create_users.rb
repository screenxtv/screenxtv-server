class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.text :email
      t.string :password_digest
      t.string :auth_key
      t.timestamps
    end
    add_index :users,:name,name:'by_name',unique:true
    add_index :users,:email,name:'by_email',unique:true
    add_index :users,:auth_key,name:'by_auth',unique:true
  end
end
