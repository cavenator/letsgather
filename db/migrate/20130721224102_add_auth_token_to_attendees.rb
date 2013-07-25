class AddAuthTokenToAttendees < ActiveRecord::Migration
  def change
		add_column :attendees, :authentication_token, :string
    add_index :attendees, :authentication_token, :unique => true
  end
end
