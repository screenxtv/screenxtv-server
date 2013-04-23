class AddDisplayNameToUser < ActiveRecord::Migration
  def up
    add_column :users, :display_name, :string
    remove_index :users,name:'by_oauth'
    remove_column :users, :oauth_provider
    remove_column :users, :oauth_uid
    remove_column :users, :oauth_token
    remove_column :users, :oauth_secret
  end
  def down
    remove_column :users, :display_name
    add_column :users, :oauth_provider, :string
    add_column :users, :oauth_uid, :integer, limit:8
    add_column :users, :oauth_token, :string
    add_column :users, :oauth_secret, :string
    add_index :users,[:oauth_provider,:oauth_uid],name:'by_oauth',unique:true
  end
end
