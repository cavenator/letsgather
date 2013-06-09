class ReminderMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	def send_rsvp_emails(email_list, event)
		@event = event
		subject = "RSVP reminder for upcoming event: #{event.name}"
		mail(to: email_list, subject: subject, from: @event.user.email)
	end

	def send_event_reminders(email_list, event)
		@event = event
		subject = "Reminder for the upcoming event: #{event.name}"
		mail(to: email_list, subject: subject, from: @event.user.email)
	end

end
