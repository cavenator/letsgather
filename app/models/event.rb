class Event < ActiveRecord::Base
		has_many :attendees
		belongs_to :user

   attr_accessible :name, :start_date, :end_date, :user_id, :supplemental_info
end
