FactoryGirl.define do
	factory :event do
		name 'event 1'
		start_date  { Date.today + 7.days}
		rsvp_date   { Date.today + 6.days }
		user
	end

		factory :event_secondary, class: Event do 
			name 'event 2'
			start_date { Date.today + 14.days }
			rsvp_date { Date.today + 13.days }
			association :user, :factory => :rico
		end
end
