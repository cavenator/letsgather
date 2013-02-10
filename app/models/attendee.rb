class Attendee < ActiveRecord::Base
		belongs_to :event
  # attr_accessible :title, :body
		attr_accessible :event_id, :user_id, :invitation_id, :full_name, :email, :rsvp, :num_of_guests, :comment, :category, :dish, :bringing_custom

		validates :event_id, :email, :rsvp, :presence => true
		validates :email, :uniqueness => { :scope => :event_id, :message => "should be unique per event" }
		validates :rsvp, :inclusion => { :in => ["Going", "Not Going", "Undecided"] , :message => "needs to be submitted with 'Going', 'Not Going', 'Undecided'" }
		validates :num_of_guests, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :message => "need to be specified with a number" }
		validates :category, :presence => {:message => "should be specified if bringing custom dish" }, :if => :bringing_custom?
		validates :dish, :presence => { :message => "should not be empty if bringing custom dish"}, :if => :bringing_custom?

		after_destroy do |attendee|
			if attendee.user_id.blank?
				role = Role.where("event_id = ?",attendee.event_id).first
			else
				role = Role.where("user_id = ? and event_id = ?", attendee.user_id, attendee.event_id).first
			end

			Role.destroy(role) unless role.blank?
		end

		#accepts an email list in the form of an Array and the event object
		def self.invite(email_list, event)
			email_hash = {"successful" => [], "unsuccessful" => [], "duplicated" => []}
			email_list.each do |email|
				if email.match(/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i)
					attendee = Attendee.new(:event_id => event.id, :email => email, :rsvp => "Undecided")
					if attendee.save
						email_hash["successful"] << email
						Thread.new { AttendeeMailer.welcome_guest(attendee).deliver }
					else
						email_hash["duplicated"] << email
					end
				else
					email_hash["unsuccessful"] << email
				end
			end
			return email_hash
		end

		def bringing_custom?
			return self.bringing_custom
		end

		def self.find_attendee_for(user, event)
			return event.attendees.where('user_id = ?', user.id).first
		end

		def self.find_rsvp_for(user, event)
			return self.find_attendee_for(user, event).rsvp
		end
end
