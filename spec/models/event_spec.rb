require 'spec_helper'

describe Event do

	before(:each) do
		User.destroy_all
		Event.destroy_all
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
			event.should have(2).error_on(:start_date)
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
			Event.destroy_all
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
			Event.destroy_all
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
			Event.destroy_all
		end

		it "should be able to parse dates into valid datetime formats in PST" do
			event = FactoryGirl.build(:event)
			expect(event).to be_valid
			event.start_date = "2014-02-02 22:10 -0700"
			expect(event).to be_valid
		end
	end

	describe "Potluck Inventory per event" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@attendee = FactoryGirl.create(:attendee)
			@event = @attendee.event
			@bob = FactoryGirl.create(:bob)
		end

		it "should be able to a potluck inventory of available and taken items per category" do
			bob_attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :user_id => @bob.id, :email => @bob.email, :rsvp => "Going")
			snack_taken_items = [{"id"=>@bob.id,"item"=>"Nachos"},{"id" => @attendee.id, "item" => "Peanuts"}]
			beer_taken_items = [{"id" => @bob.id, "item" => "Amber Ale"}]
			potluck_list1 = FactoryGirl.create(:potluck_item, :event_id => @event.id, :taken_items => beer_taken_items)
			potluck_list2 = FactoryGirl.create(:potluck_item, :event_id => @event.id, :category => "Snacks",:dishes => ["Ahi Tuna","Spring Rolls"], :taken_items => snack_taken_items)

			expected_list = [{"category" => "Beer", "available_items" =>["Stout", "IPA", "Pale Ale","Brown Ale"], "taken_items" => beer_taken_items}, {"category" => "Snacks", "available_items" => ["Ahi Tuna","Spring Rolls"], "taken_items" => snack_taken_items }]

			expect(@event.get_potluck_inventory_for_categories(["Beer","Snacks"])).to eql(expected_list)
			expect(@event.get_potluck_list_per_category("Beer")).to eql(potluck_list1)
		end
	end

	describe "Determine RSVP reminder" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should get all events whose rsvp date is between 2 - 3 days away" do
			@event = FactoryGirl.create(:event, :rsvp_date => Time.now + 2.days + 12.hours, :start_date => 5.days.from_now)
			events = Event.get_events_for_rsvp_reminders

			expect(events.count) == 1
			expect(events).to_not be_empty
		end

		it "should ignore all events whose rsvp date is not within the 2-3 day date range" do
			@event = FactoryGirl.create(:event, :rsvp_date => Time.now + 5.days, :start_date => Time.now + 7.days)
			events = Event.get_events_for_rsvp_reminders
			expect(events).to be_blank
		end
	end

	describe "Determine Event Reminder" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should get all events whose start date is roughly 1 - 2 days away" do
			@event = FactoryGirl.create(:event, :rsvp_date =>Time.now, :start_date => Time.now + 1.day + 12.hours)
			events = Event.get_events_for_event_reminders

			expect(events.count) == 1
			expect(events).to_not be_empty
		end

		it "should ignore all events whose start date is farther than the 1-2 day range" do
			@event = FactoryGirl.create(:event, :rsvp_date => Time.now + 1.day, :start_date => 3.days.from_now)
			events = Event.get_events_for_event_reminders

			expect(events).to be_blank
		end
	end

	describe "User future settings applied to created events" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should use default settings if future_options is nil" do
			@event = FactoryGirl.create(:event)
			expect(@event.settings.notify_on_guest_accept) == false
			expect(@event.settings.notify_on_guest_decline) == false
			expect(@event.settings.notify_on_guest_response) == false
			expect(@event.settings.days_rsvp_reminders) == 0
			expect(@event.settings.days_event_reminders) == 0
		end

		it "should copy over users default settings into created event" do
			@user = FactoryGirl.create(:user)
			expected_settings = {"notify_on_guest_accept" => true, "notify_on_guest_decline" => true, "days_rsvp_reminders" => 2, "days_event_reminders" => 1}
			@user.future_options = Settings.DEFAULT_SETTINGS.merge(expected_settings)
			@user.future_options = @user.future_options.merge(Settings.AdditionalHashInfoForUser)
			@user.save

			@event = FactoryGirl.create(:event, :user_id => @user.id)
			@settings = Settings.find_by_event_id(@event.id)
			expect(@settings.notify_on_guest_accept) == @user.future_options["notify_on_guest_accept"]
			expect(@settings.notify_on_guest_decline) == @user.future_options["notify_on_guest_decline"]
			expect(@settings.notify_on_guest_response) == @user.future_options["notify_on_guest_response"]
			expect(@settings.days_rsvp_reminders) == @user.future_options["days_rsvp_reminders"]
			expect(@settings.days_event_reminders) == @user.future_options["days_event_reminders"]
		end
	end
end
