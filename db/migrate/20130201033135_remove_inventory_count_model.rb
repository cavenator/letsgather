class RemoveInventoryCountModel < ActiveRecord::Migration
  def change
		drop_table :inventory_counts
  end
end
