FactoryGirl.define do
	factory :event do
		name 'event 1'
		start_date  { Date.today + 7.days}
		user
	end
end
