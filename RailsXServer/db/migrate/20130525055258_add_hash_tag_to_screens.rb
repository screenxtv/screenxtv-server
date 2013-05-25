class AddHashTagToScreens < ActiveRecord::Migration
  def change
    add_column :screens, :hash_tag, :string
  end
end
