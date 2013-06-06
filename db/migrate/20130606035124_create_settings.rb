class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
			t.integer :event_id, :null => false
			t.boolean :notify_on_guest_accept, :default=> false
			t.boolean :notify_on_guest_decline, :default => false
			t.boolean :notify_on_guest_response, :default => false
			t.integer :days_rsvp_reminders, :default => 0
			t.integer :days_event_reminders, :default => 0
      t.timestamps
    end
  end
end
