class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   :name,null:false
      t.string     :email,null:false
      t.string   :password_digest,null:false
      t.string   :auth_key,null:false
      t.boolean  :email_verified,default:false

      t.string   :oauth_provider
      t.integer  :oauth_uid, limit:8
      t.string   :oauth_token
      t.string   :oauth_secret

      t.timestamps
    end
    add_index :users,:name,name:'by_name',unique:true
    add_index :users,:email,name:'by_email',unique:true
    add_index :users,[:oauth_provider,:oauth_uid],name:'by_oauth',unique:true
  end
end
