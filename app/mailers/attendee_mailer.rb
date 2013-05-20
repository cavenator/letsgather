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
		email_list = group.map(&:email).compact
		@event = event
		@body = body
		mail(to: email_list, subject: subject, :from => @event.user.email)
	end

	#guest = an Attendee object
	def email_guest(guest, subject, body, sender)
		@body = body
		@event = guest.event
		@host = @event.user
		@sender = sender
		mail(to: guest.email, subject: subject, from: @event.user.email)
	end

	def email_host(hosts, event, subject, body, sender)
		@body = body
		@event = event
		@sender = sender
		hosts_email = hosts.map{|host| host.email }
		mail(to: hosts_email, subject: subject )
	end

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

	def send_event_cancellation(email_list, event)
		@event= event
		subject = "Cancelled: #{event.name} hosted by #{event.user.full_name}"
		mail(to: email_list, subject: subject, from: @event.user.email )
	end

	def send_host_guest_acknowledgement(email_hash, event)
		subject = "Invitation summary for event #{event.name}"
		@invitation_summary_hash = email_hash
		mail(to: event.user.email, subject: subject)
	end
end
