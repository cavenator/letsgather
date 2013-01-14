class Attendee < ActiveRecord::Base
		belongs_to :event
  # attr_accessible :title, :body
		attr_accessible :event_id, :user_id, :invitation_id, :full_name, :email, :rsvp

		validates :event_id, :email, :rsvp, :presence => true

		#accepts an email list in the form of an Array and the event object
		def self.invite(email_list, event)
			email_hash = {"successful" => [], "unsuccessful" => []}
			email_list.each do |email|
				if email.match(/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i)
					email_hash["successful"] << email
					attendee = Attendee.create(:event_id => event.id, :email => email, :rsvp => "Undecided")
					AttendeeMailer.welcome_guest(attendee).deliver
				else
					email_hash["unsuccessful"] << email
				end
			end
			return email_hash
		end
end
