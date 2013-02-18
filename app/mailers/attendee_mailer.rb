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

	#group = list of attendees (or guests)
	#The list of emails can be an array of email addresses or a single string with the addresses separated by commas. (Straight from ruby on rails guide)
	# The @body is passed along and so is the event to the view
	def email_group(group, event, subject, body)
		email_list = group.map(&:email)
		@event = event
		@body = body
		mail(to: email_list, subject: subject, :from => @event.user.email)
	end

	#guest = an Attendee object
	def email_guest(guest, subject, body)
		@body = body
		@event = guest.event
		mail(to: guest.email, subject: subject, :from => @event.user.email)
	end
end
