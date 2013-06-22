class AddIsHostToAttendee < ActiveRecord::Migration
  def change
		add_column :attendees, :is_host, :boolean, :default => false
  end
end
