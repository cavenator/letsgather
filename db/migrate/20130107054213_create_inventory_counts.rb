class CreateInventoryCounts < ActiveRecord::Migration
  def change
    create_table :inventory_counts do |t|
			t.integer :event_id, :default=>0
			t.integer :app_count, :default=>0
			t.integer :main_dish_count, :default=>0
			t.integer :salads_count, :default=>0
			t.integer :sides_count, :default=>0
			t.integer :desserts_count, :default=>0
			t.integer :drinks_count, :default=>0
      t.timestamps
    end
  end
end
