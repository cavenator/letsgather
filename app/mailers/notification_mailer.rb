class NotificationMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	def notify_host_of_attending_guest(attendee, event)
		@attendee = attendee
		@event = event
		mail(to: event.user.email, subject: "Invitation accepted for event #{event.name}")
	end

	def notify_host_of_declining_guest(attendee, event)
		@attendee = attendee
		@event = event
		mail(to: event.user.email, subject: "Invitation declined for event #{event.name}")
	end
end
