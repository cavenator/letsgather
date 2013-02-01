class CreatePotluckItems < ActiveRecord::Migration
  def change
    create_table :potluck_items do |t|
			t.integer :event_id
			t.string  :category
			t.text    :dishes
			t.integer :host_quantity
      t.timestamps
    end
  end
end
