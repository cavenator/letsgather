class AddOptionsToUsers < ActiveRecord::Migration
  def change
		add_column :users, :future_options, :text
  end
end
