require 'spec_helper'

describe Event do

	before(:all) do
		User.destroy_all
	end

	describe "minimal event requirements" do
		it "should always have a name" do
			event = FactoryGirl.build(:event, :name=>nil)
			expect(event).to_not be_valid
			event.save
			event.should have(1).error_on(:name)
		end

		it "should always have a start date" do
			event = FactoryGirl.build(:event, :start_date => nil)
			expect(event).to_not be_valid
			event.save
			event.should have(1).error_on(:start_date)
		end

		it "should always start in the future" do
			event = FactoryGirl.build(:event, :start_date => (Date.today - 1.day))
			expect(event).to_not be_valid
		end
	
		it "should always have an rsvp date" do
			event = FactoryGirl.build(:event, :rsvp_date => nil)
			expect(event).to_not be_valid
		end

		it "should have an rsvp that is not greater than the event start date" do
			event = FactoryGirl.build(:event, :rsvp_date => 7.days.from_now)
			expect(event).to_not be_valid
		end
	end

	describe "user minimum requirements before creating event" do
		before(:all) do
			User.destroy_all
		end

		it "should check to ensure that a user has an email" do
			event = FactoryGirl.create(:event)
			Event.should have(1).record
			User.should have(1).record
			expect(event.user.email).to eql("alice.cooper@gmail.com")
		end

	end

	describe "Finding the responses for an event" do
		before(:all) do
			User.destroy_all
			@event = FactoryGirl.create(:event)
			@host = @event.user
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)
			Attendee.create(:event_id => @event.id, :user_id => @bob.id, :rsvp => "Going", :email => @bob.email)
			Attendee.create(:event_id => @event.id, :user_id => @rico.id, :rsvp => "Not Going", :email => @rico.email)
		end

		it "should tell you the amount of people going" do
			expect(@event.attending_guest_count) == 1
		end

	end

	describe "Start Date and RSVP parsing" do
		before(:all) do
			User.destroy_all
		end

		it "should be able to parse dates into valid datetime formats in PST" do
			event = FactoryGirl.build(:event)
			expect(event).to be_valid
			start_date = "2014-02-02 22:10 -0800"
			expect(event).to be_valid
		end
	end

end
