class ReminderMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	def send_rsvp_emails(guest)
		@attendee = guest
		@event = Event.find(guest.event_id)
		subject = "RSVP reminder for upcoming event: #{@event.name}"
		mail(to: guest.email, subject: subject, from: @event.user.email)
	end

	def send_event_reminders(guest)
		@attendee = guest
		@event = Event.find(guest.event_id)
		subject = "Reminder for the upcoming event: #{@event.name}"
		mail(to: guest.email, subject: subject, from: @event.user.email)
	end

end
