class MessageMailer < ActionMailer::Base

	def email_group(group, event, subject, body)
		email_list = group.map(&:email).compact
		@event = event
		@body = body
		mail(to: email_list, subject: subject, from: @event.user.email)
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
		mail(to: hosts_email, subject: subject, from: @sender.email)
	end

end
