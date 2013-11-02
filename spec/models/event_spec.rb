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
			event.should have(1).error_on(:start_date)
		end

		it "should always have an end date" do
			event = FactoryGirl.build(:event, :end_date => nil)
			expect(event).to_not be_valid
			expect(event).to have(1).error_on(:end_date)
		end

		it "should always have a contact number" do
			event = FactoryGirl.build(:event, :contact_number => nil)
			expect(event).to_not be_valid
			expect(event).to have(2).errors_on(:contact_number)
			event.contact_number = "(555) 555-5555"
			expect(event).to be_valid
		end

		it "should always start in the future" do
			event = FactoryGirl.build(:event, :start_date => (Date.today - 1.day))
			expect(event).to_not be_valid
		end
	
		it "should have a end date that is not before the start date" do
			event = FactoryGirl.build(:event, :end_date => 6.days.from_now)
			expect(event).to_not be_valid
			expect(event).to have(1).error_on(:start_date)
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
			event.start_date = event.start_date.to_s
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
			snack_taken_items = [{"guests"=>[@bob.id],"item"=>"Nachos"},{"guests" => [@attendee.id], "item" => "Peanuts"}]
			beer_taken_items = [{"guests" => [@bob.id], "item" => "Pale Ale"}]
			potluck_list1 = FactoryGirl.create(:potluck_item, :event_id => @event.id, :category => "Beer", :taken_items => beer_taken_items)
			potluck_list2 = FactoryGirl.create(:potluck_item, :event_id => @event.id, :category => "Snacks",:dishes => [{"item" =>"Ahi Tuna", "quantity" => 1},{"item" => "Spring Rolls", "quantity" =>3 },{"item" => "Nachos", "quantity" => 1},{"item" => "Peanuts", "quantity" => 1}], :taken_items => snack_taken_items)

			expected_list = [{"category" => "Beer", "available_items" =>[{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 1}], "taken_items" => beer_taken_items}, {"category" => "Snacks", "available_items" => [{"item" => "Ahi Tuna", "quantity" => 1},{"item" => "Spring Rolls", "quantity" => 3}, {"item"=>"Nachos", "quantity"=>1}, {"item"=>"Peanuts", "quantity"=>1}], "taken_items" => snack_taken_items }]

			expect(@event.get_potluck_inventory_for_categories(["Beer","Snacks"])).to eql(expected_list)
			expect(@event.get_potluck_list_per_category("Beer")).to eql(potluck_list1)
		end
	end

	describe "Reminder Settings" do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			@user = FactoryGirl.create(:user)
			@bob = FactoryGirl.create(:bob)
			contact_number = "(555) 555-5555"
			@event1 = Event.create(:user_id => @user.id, :name => "event 1", :rsvp_date =>  2.days.from_now, :start_date => 4.days.from_now, :end_date => (4.days.from_now + 3.hours), :contact_number => contact_number)
			@event2 = Event.create(:user_id => @bob.id, :name => "event 2", :rsvp_date => 1.day.from_now, :start_date => 2.days.from_now, :end_date => (2.days.from_now + 1.hour), :contact_number => contact_number)
			@event3 = Event.create(:user_id => @user.id, :name => "event 3", :rsvp_date =>  2.days.from_now, :start_date => 3.days.from_now, :end_date => (3.days.from_now + 2.hours), :contact_number => contact_number)
			@event4 = Event.create(:user_id => @bob.id, :name => "event 4", :rsvp_date => 1.day.from_now, :start_date => 2.days.from_now, :end_date => (2.days.from_now + 4.hours), :contact_number => contact_number)
			@event1.settings = Settings.new
			@event2.settings = Settings.new
			@event3.settings = Settings.new
			@event4.settings = Settings.new

			@event1.settings.days_rsvp_reminders = 2
			@event4.settings.days_rsvp_reminders = 1
			@event2.settings.days_event_reminders = 2
			@event3.settings.days_event_reminders = 3

			@event1.settings.save
			@event2.settings.save
			@event3.settings.save
			@event4.settings.save
		end

		it "should fetch events whose rsvp_reminder settings match the days from rsvp_date" do
			rsvp_events = Event.events_for_rsvp_reminders
			expect(rsvp_events.count) == 2
			expect(rsvp_events).to include(@event1)
			expect(rsvp_events).to include(@event4)
		end

		it "should send emails for events whose event_reminder settings match the days from start_date" do
			events = Event.events_for_event_reminders
			expect(events.count) == 2
			expect(events).to include(@event2)
			expect(events).to include(@event3)
		end
	end

	describe "User future settings applied to created events" do
#		before(:each) do
#			User.destroy_all
#			Event.destroy_all
#		end

		it "should copy over users default settings into created event"

	end
end
