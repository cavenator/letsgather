class AddRsvpDateToEvents < ActiveRecord::Migration
  def change
		add_column :events, :rsvp_date, :datetime
  end
end
