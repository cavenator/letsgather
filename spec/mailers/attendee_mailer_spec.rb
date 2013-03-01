require "spec_helper"

describe AttendeeMailer do
	
	describe "Inviting Guests" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@attendee = FactoryGirl.create(:attendee, :rsvp => 'Going')
		end

		it "should send invitations to new attendees" do
			AttendeeMailer.welcome_guest(@attendee).deliver
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end

		it "should be able to send email to a group of people" do
			attendees = []
			attendees << @attendee
			attendees << FactoryGirl.create(:attendee, :event_id => @attendee.event.id, :rsvp => 'Going')
			expect(attendees.count) == 2
			AttendeeMailer.email_group(attendees, @attendee.event, subject, body).deliver
			expect(ActionMailer::Base.deliveries).to have(2).things
		end
	end
end
