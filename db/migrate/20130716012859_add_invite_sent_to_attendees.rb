class AddInviteSentToAttendees < ActiveRecord::Migration
  def change
		add_column :attendees, :invite_sent, :boolean, :default => false
  end
end
