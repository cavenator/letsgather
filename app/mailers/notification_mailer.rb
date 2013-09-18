class NotificationMailer < ActionMailer::Base
  default from: "mydevmailer@gmail.com"

	def notify_host_of_attending_guest(attendee, event)
		@attendee = attendee
		@event = event
		hosts_email = event.get_hosts.map{|host| host.email}
		mail(to: hosts_email, subject: "Invitation accepted for event #{event.name}")
	end

	def notify_host_of_declining_guest(attendee, event)
		@attendee = attendee
		@event = event
		hosts_email = event.get_hosts.map{|host| host.email}
		mail(to: hosts_email, subject: "Invitation declined for event #{event.name}")
	end

	def notify_host_of_all_guest_changes(attendee, differences, event)
		@attendee = attendee
		@differences_hash = differences
		@event = event
		hosts_email = event.get_hosts.map{|host| host.email}
		mail(to: hosts_email, subject: "Response changed: #{event.name}")
	end
end
