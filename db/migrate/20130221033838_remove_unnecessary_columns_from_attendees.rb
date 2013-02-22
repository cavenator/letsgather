class RemoveUnnecessaryColumnsFromAttendees < ActiveRecord::Migration
  def change
		remove_column :attendees, :invitation_id
		remove_column :attendees, :category
		remove_column :attendees, :bringing_custom
  end
end
