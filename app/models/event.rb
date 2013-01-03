class Event < ActiveRecord::Base
		has_many :attendees
		belongs_to :user

		validates :name,:user_id, :start_date, :presence => true
		validate :start_date_must_be_in_the_future

   attr_accessible :name, :start_date, :end_date, :user_id, :supplemental_info, :address1, :address2, :city, :state, :zip_code

	def start_date_must_be_in_the_future
			unless self.start_date.eql?(nil)
				errors.add(:start_date,"cannot start in the past") if self.start_date < Date.today
			end
	end

	def location
		return (self.address1 + self.address2 + self.city + self.state + self.zip_code).length > 0
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
