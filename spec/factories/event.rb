FactoryGirl.define do
	factory :event do
		name 'event 1'
		start_date  { Date.today + 7.days}
		rsvp_date   { 6.days.from_now }
		user
	end

		factory :event_secondary, class: Event do 
			name 'event 2'
			start_date { 14.days.from_now }
			rsvp_date {13.days.from_now }
			association :user, :factory => :rico
		end
end
