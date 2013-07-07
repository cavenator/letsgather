class SuggestionMailer < ActionMailer::Base
  default from: "letsgather.apartyapp@gmail.com"

	def notify_hosts(suggestion, event)
		host_emails = event.get_hosts.map{ |host| host.email }
		@suggestion = suggestion
		subject = "A guest has made a suggestion to #{event.name}"
		mail(to: host_emails, subject: subject)
	end

	def approval_email(email, category)
		subject = "Your suggestion for #{category} has been approved"
		mail(to: email, subject: subject)
	end

	def rejection_email(email, category)
		subject = "Your suggestion for #{category} has been rejected"
		mail(to: email, subject: subject)
	end
end
