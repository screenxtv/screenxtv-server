class AddCastCountToScreen < ActiveRecord::Migration
  def change
    add_column :screens, :cast_count, :integer, default: 0
  end
end
