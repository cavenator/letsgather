class AddCustomColumnForAttendee < ActiveRecord::Migration
  def change
		add_column :attendees, :bringing_custom, :boolean, :default => false
  end
end
