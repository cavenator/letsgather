require "spec_helper"

describe AttendeeMailer do
	
	describe "Inviting Guests" do
		it "should send emails to new attendees" do
			attendee = FactoryGirl.create(:attendee)
			email = AttendeeMailer.welcome_guest(attendee).deliver
	#		ActionMailer::Base.deliveries.length > 0
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end
	end
end
