require "spec_helper"

describe AttendeeMailer do
	
	describe "Inviting Guests" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@attendee = FactoryGirl.create(:attendee, :rsvp => 'Going')
		end

		it "should send invitations to new attendees" do
			AttendeeMailer.welcome_guest(@attendee, @attendee.event.user).deliver
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end

	end
end
