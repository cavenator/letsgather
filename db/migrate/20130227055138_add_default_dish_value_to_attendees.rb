class AddDefaultDishValueToAttendees < ActiveRecord::Migration
  def change
		change_column_default :attendees, :dish, []
  end
end
