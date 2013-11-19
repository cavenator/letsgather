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

	def notify_guest_of_new_privileges(attendee, role, host)
		@attendee = attendee
		@event = attendee.event
		@host = host
		if role.eql?(Role.HOST)
			subject = "You have been asked to cohost #{@event.name}"
			template_name = "notify_guest_of_cohost_privileges"
		else
			subject = "You are no longer cohosting #{@event.name}"
			template_name = "notify_guest_of_demotion"
		end
		attachments.inline['logo.png'] = File.read("#{Rails.root.to_s + '/app/assets/images/LG_Lets_Gather_480.png'}")
		mail(to: attendee.email, subject: subject, template_name: template_name )
	end
end
