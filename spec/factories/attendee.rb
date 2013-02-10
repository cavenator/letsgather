FactoryGirl.define do
	factory :attendee do
		sequence(:email) {|n| "person#{n}@gmail.com" }
		rsvp "Undecided"
		num_of_guests 0
		event
	end
end
