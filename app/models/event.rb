class Event < ActiveRecord::Base
		has_many :attendees
		belongs_to :user

		validates :name,:user_id, :start_date, :presence => true
		validate :start_date_must_be_in_the_future

   attr_accessible :name, :start_date, :end_date, :user_id, :supplemental_info

	def start_date_must_be_in_the_future
			unless self.start_date.eql?(nil)
				errors.add(:start_date,"cannot start in the past") if self.start_date < Date.today
			end
	end
end
