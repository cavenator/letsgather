class Event < ActiveRecord::Base
		has_many :attendees, :dependent => :destroy
		belongs_to :user
		has_one :inventory_count, :dependent => :destroy

		validates :name,:user_id, :start_date, :rsvp_date, :presence => true
		validate :start_date_must_be_in_the_future
		validate :rsvp_date_should_be_less_than_start_date

   attr_accessible :name, :start_date, :end_date, :user_id, :rsvp_date, :supplemental_info, :address1, :address2, :city, :state, :zip_code

	after_create do |event|
		InventoryCount.create(:event_id => event.id)
	end

	def start_date_must_be_in_the_future
			unless self.start_date.eql?(nil)
				errors.add(:start_date,"cannot start in the past") if self.start_date < Date.today
			end
	end

	def rsvp_date_should_be_less_than_start_date
		unless self.rsvp_date.eql?(nil) || self.start_date.eql?(nil)
			errors.add(:rsvp_date, "rsvp date must be before the event start date") if self.rsvp_date >= self.start_date
		end
	end

	def display_start_time
		return self.start_date.in_time_zone('Pacific Time (US & Canada)').strftime("%b %d,%Y %I:%M %P")
	end

	def display_rsvp_time
		return self.rsvp_date.in_time_zone('Pacific Time (US & Canada)').strftime("%b %d,%Y %I:%M %P")
	end

	def attending_guest_count
		return self.attendees.where("rsvp = 'Going'").count
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
end
