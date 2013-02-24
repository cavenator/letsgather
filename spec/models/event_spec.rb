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

end
