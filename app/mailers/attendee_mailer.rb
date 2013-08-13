class AttendeeMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	#guest = an Attendee object
	def welcome_guest(guest, host)
		@attendee = guest
		@event = Event.find(guest.event_id)
		@host = host
		calendar_event = CalendarInviteBuilder.createCalendarInviteFor(@event, guest.email)

		attachments['event.ics'] = {:mime_type => 'text/calendar', :content => calendar_event.export() } 
		subject = "You have been invited to #{@event.name} by #{@host.full_name}"
		mail(to: guest.email, subject: subject)
	end

	def send_updated_calendar(event)
		email_list = event.attendees.map(&:email).compact
		@event = event
		calendar_event = CalendarInviteBuilder.createCalendarInvitesFor(@event, email_list)
		attachments['event.ics'] = {:mime_type => 'text/calendar', :content => calendar_event.export() }
		subject = "Updated event info for #{event.name}"
		mail(to: email_list, subject: subject)

	end

	def send_event_cancellation(email_list, event_name, host_name, email)
		@host_name = host_name
		@name = event_name
		subject = "Cancelled: #{event_name} hosted by #{host_name}"
		mail(to: email_list, subject: subject, from: email )
	end

	def send_host_guest_acknowledgement(email_hash, event)
		subject = "Invitation summary for event #{event.name}"
		@invitation_summary_hash = email_hash
		hosts_email = event.get_hosts.map{|host| host.email}
		mail(to: hosts_email, subject: subject)
	end
end
