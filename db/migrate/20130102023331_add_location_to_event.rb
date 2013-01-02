class AddLocationToEvent < ActiveRecord::Migration
  def change
		add_column :events, :address1, :string
		add_column :events, :address2, :string
		add_column :events, :city, :string
		add_column :events, :state, :string
		add_column :events, :zip_code, :string
  end
end
