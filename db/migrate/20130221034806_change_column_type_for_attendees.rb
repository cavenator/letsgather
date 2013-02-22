class ChangeColumnTypeForAttendees < ActiveRecord::Migration
  def change
		change_column :attendees, :dish, :text
  end
end
