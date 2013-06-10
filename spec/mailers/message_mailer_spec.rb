require "spec_helper"

describe MessageMailer do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			@attendee = FactoryGirl.create(:attendee, :rsvp => 'Going')
		end

		it "should be able to send email to a group of people" do
			attendees = []
			attendees << @attendee
			attendees << FactoryGirl.create(:attendee, :event_id => @attendee.event.id, :rsvp => 'Going')
			expect(attendees.count) == 2
			subject = "Hey you"
			body = "Please tell me this is working"
			MessageMailer.email_group(attendees, @attendee.event, subject, body).deliver
			expect(ActionMailer::Base.deliveries).to have(1).things
		end
end
