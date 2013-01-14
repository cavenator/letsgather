FactoryGirl.define do
	factory :attendee do
		sequence(:email) {|n| "person#{n}@gmail.com" }
		rsvp "Undecided"
		event
	end
end
