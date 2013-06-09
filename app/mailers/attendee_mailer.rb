class AttendeeMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	#guest = an Attendee object
	def welcome_guest(guest, host)
		@attendee = guest
		@event = Event.find(guest.event_id)
		@host = host
		subject = "You have been invited to #{@event.name} by #{@host.full_name}"
		mail(to: guest.email, subject: subject)
	end

	def send_event_cancellation(email_list, event)
		@event= event
		subject = "Cancelled: #{event.name} hosted by #{event.user.full_name}"
		mail(to: email_list, subject: subject, from: @event.user.email )
	end

	def send_host_guest_acknowledgement(email_hash, event)
		subject = "Invitation summary for event #{event.name}"
		@invitation_summary_hash = email_hash
		hosts_email = event.get_hosts.map{|host| host.email}
		mail(to: hosts_email, subject: subject)
	end
end
