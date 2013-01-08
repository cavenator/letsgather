FactoryGirl.define do
	factory :event do
		name 'event 1'
		start_date  { Date.today + 7.days}
		rsvp_date   { 6.days.from_now }
		user
	end
end
