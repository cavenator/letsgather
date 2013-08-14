FactoryGirl.define do
	factory :event do
		name 'event 1'
		start_date  { Date.today + 7.days}
		rsvp_date   { Date.today + 6.days }
		end_date {DateTime.now + 7.days + 3.hours}
		contact_number '(555) 555-5555'
		user
	end

		factory :event_secondary, class: Event do 
			name 'event 2'
			start_date { Date.today + 14.days }
			end_date {DateTime.now + 14.days + 2.hours}
			rsvp_date { Date.today + 13.days }
			contact_number '(555) 555-5555'
			association :user, :factory => :rico
		end
end
