class NotificationUtil

	def self.send_notifications_to_host_from(updated_attendee)
		@event = updated_attendee.event
		previous_state = Attendee.find(updated_attendee.id)

		if @event.settings.notify_on_guest_accept && updated_attendee.rsvp.eql?('Going') && !previous_state.rsvp.eql?('Going')
			NotificationMailer.delay.notify_host_of_attending_guest(updated_attendee, @event)
		elsif @event.settings.notify_on_guest_decline && updated_attendee.rsvp.eql?('Not Going') && !previous_state.rsvp.eql?('Not Going')
			NotificationMailer.delay.notify_host_of_declining_guest(updated_attendee, @event)
		end
	end
end
