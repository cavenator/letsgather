class AddRsvpColumnsToAttendee < ActiveRecord::Migration
  def change
		add_column :attendees, :num_of_guests, :integer, :default => 0
		add_column :attendees, :comment, :string
  end
end
