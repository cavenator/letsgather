class CreateAttendees < ActiveRecord::Migration
  def change
    create_table :attendees do |t|
			t.integer  :event_id
			t.integer  :user_id
			t.integer  :invitation_id
			t.string   :full_name
			t.string   :email
			t.string   :rsvp
      t.timestamps
    end
  end
end
