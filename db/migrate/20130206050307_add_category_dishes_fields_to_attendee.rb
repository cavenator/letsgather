class AddCategoryDishesFieldsToAttendee < ActiveRecord::Migration
  def change
		add_column :attendees, :category, :string
		add_column :attendees, :dish, :string
  end
end
