require "spec_helper"

describe NotificationMailer do
	describe "Notification of attending guests" do

		before(:each) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@user = @event.user
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)
			@attendee = FactoryGirl.create(:attendee, :user_id => @bob.id, :event_id => @event.id)
			@attendee2 = FactoryGirl.create(:attendee, :user_id => @rico.id, :event_id => @event.id)
			@event.settings.notify_on_guest_accept = true
			@event.settings.notify_on_guest_decline = true
			@event.settings.notify_on_guest_response = true
			@event.settings.save
		end

		it "should send out notifications when a guest accepts and the setting is turned on" do
			@attendee.rsvp = "Going"
			@attendee.save
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end

		it "should send out notifications when a guest accepts and the setting is turned on" do
			@attendee2.rsvp = "Not Going"
			@attendee2.save
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end

		it "should sent out notifications when a guest changes something in their response and the setting is turned on" do
#			@attendee.rsvp = "Undecided"
			@attendee.comment = "I'll get back to you later!"
			@attendee.save
			expect(ActionMailer::Base.deliveries).to have(1).thing
		end
	end
end
