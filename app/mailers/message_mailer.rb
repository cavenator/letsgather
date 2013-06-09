class MessageMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

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

end
