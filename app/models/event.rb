class Event < ActiveRecord::Base
		has_many :attendees, :dependent => :destroy
		has_many :potluck_items, :dependent => :destroy
		belongs_to :user

		validates :name,:user_id, :start_date, :rsvp_date, :presence => true
		validate :start_date_must_be_in_right_format
		validate :rsvp_date_must_be_in_right_format
		validate :start_date_must_be_in_the_future
		validate :rsvp_date_should_be_less_than_start_date

   attr_accessible :name, :start_date, :end_date, :user_id, :rsvp_date, :supplemental_info, :address1, :address2, :city, :state, :zip_code

	def start_date_must_be_in_the_future
			unless self.start_date.eql?(nil)
				errors.add(:start_date,"cannot start in the past") if self.start_date < Date.today
			end
	end

	def rsvp_countdown
		days = ((self.rsvp_date.in_time_zone("Pacific Time (US & Canada)") - Time.now.in_time_zone("Pacific Time (US & Canada)"))/86400).ceil
		unless days == 1
			statement = "You have "+days.to_s+" days left to RSVP"
		else
			statement = "You have 1 day left to RSVP"
		end
		return statement
	end

	def start_date_must_be_in_right_format
		errors.add(:start_date, 'must be a valid datetime format (YYYY-MM-DD HH:MM -0700)') if ((DateTime.parse(self.start_date.to_s) rescue ArgumentError) == ArgumentError)
	end

	def rsvp_date_must_be_in_right_format
		errors.add(:rsvp_date, 'must be a valid datetime format (YYYY-MM-DD HH:MM -0700)') if ((DateTime.parse(self.rsvp_date.to_s) rescue ArgumentError) == ArgumentError)
	end

	def rsvp_date_should_be_less_than_start_date
		unless self.rsvp_date.eql?(nil) || self.start_date.eql?(nil)
			errors.add(:rsvp_date, "rsvp date must be before the event start date") if self.rsvp_date >= self.start_date
		end
	end

	def display_start_time
		return self.start_date.in_time_zone("Pacific Time (US & Canada)").strftime("%b %d,%Y %I:%M %P")
	end

	def display_rsvp_time
		return self.rsvp_date.in_time_zone("Pacific Time (US & Canada)").strftime("%b %d,%Y %I:%M %P")
	end

	def attending_guest_count
		attending_guests = self.attendees.where("rsvp = 'Going'")
		guest_count = attending_guests.count
		attending_guests.each do |attendee|
			guest_count += attendee.num_of_guests
		end
		return guest_count
	end

	def location
		return true unless self.address1.eql?(nil)
	end

	def location1
		returnString = String.new
		returnString += self.address1 if self.address1
		returnString += (", "+self.address2) if self.address2 && self.address1
		return returnString
	end

	def location2
		returnString = String.new
		returnString += self.city if self.city
		returnString += ", "+self.state if self.state
		returnString += "  "+self.zip_code if self.zip_code && self.state
		return returnString
	end

	def get_potluck_items_for_guests
		items_for_guests = []
		self.potluck_items.each do |item|
			items_for_guests << {"category" => item.category, "dishes" => item.dishes}
		end
		return items_for_guests
	end
	
end
