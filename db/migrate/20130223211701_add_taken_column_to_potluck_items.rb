class AddTakenColumnToPotluckItems < ActiveRecord::Migration
  def change
		add_column :potluck_items, :taken_items, :text, :default => []
  end
end
