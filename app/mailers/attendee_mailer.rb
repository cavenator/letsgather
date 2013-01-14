class AttendeeMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	#guest = an Attendee object
	def welcome_guest(guest)
		@attendee = guest
		@event = Event.find(guest.event_id)
		@host = User.find(@event.user_id)
		subject = "You have been invited to #{@event.name} by #{@host.full_name}"
		mail(to: guest.email, subject: subject)
	end
end
