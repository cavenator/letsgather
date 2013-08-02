class MessageMailer < ActionMailer::Base

	def email_group(email_list, event, subject, body, sender)
		@event = event
		@body = body
		@sender = sender
		mail(to: email_list, subject: subject, from: @event.user.email)
	end

	#guest = an Attendee object
	def email_guest(guest, subject, body, sender)
		@body = body
		@event = guest.event
		@sender = sender
		mail(to: guest.email, subject: subject, from: @event.user.email)
	end

	def email_host(hosts, event, subject, body, sender)
		@body = body
		@event = event
		@sender = sender
		hosts_email = hosts.map{|host| host.email }
		mail(to: hosts_email, subject: subject, from: @sender.email)
	end

end
