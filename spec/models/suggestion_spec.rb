require 'spec_helper'

describe Suggestion do
	describe "minimal requirements" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@guest = Attendee.create(:event_id => @event.id, :rsvp => "going", :email => "guest.person@gmail.com", :full_name => "ba barracus")
		end

		it "should have a category, new_or_existing and be linked to an event" do

			suggestion = Suggestion.new(:suggested_items => [])
			expect(suggestion).to_not be_valid

			suggestion.category = "Wine"
			suggestion.event_id = @event.id
			suggestion.new_or_existing = "New"
			suggestion.requester_name = "Don Quixote"
			suggestion.requester_email = "don.q@gmail.com"
			
			expect(suggestion).to be_valid

		end

		it "should only be allowed to have 'New' or 'Existing'" do
			@suggestion = Suggestion.new(:category => "Beer", :suggested_items => ["IPA"], :new_or_existing => "Radical", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)

			expect(@suggestion).to_not be_valid
			@suggestion.new_or_existing = "New"
			expect(@suggestion).to be_valid
		end
	end

	describe "requesting new lists" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@guest = Attendee.create(:event_id => @event.id, :rsvp => "going", :email => "guest.person@gmail.com", :full_name => "ba barracus")
			@existing_list = PotluckItem.create(:event_id => @event.id, :category => "Appetizers", :host_quantity => 1, :dishes => [{"item" => "Nachos", "quantity" => 1},{"item" => "Buffalo Wings", "quantity" => 1},{"item" => "Taquitos", "quantity" => 1}])
		end

		it "should not try to suggest a category that exists" do
			@suggestion = Suggestion.new(:category => "appetizers", :suggested_items => ["fries"], :new_or_existing => "New", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@suggestion).to_not be_valid

			@suggestion.category = "Sides"
			expect(@suggestion).to be_valid
		end

		it "should not have duplicate dishes within the suggestion" do
			@suggestion = Suggestion.new(:category => "Beer", :suggested_items => ["IPA", "ipa", "Pale Ale"], :new_or_existing => "New", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@suggestion).to_not be_valid

			@suggestion.suggested_items[1] = "Stout"
			expect(@suggestion).to be_valid
		end

		it "should only have unique categories per event and new" do
			@suggestion = Suggestion.new(:category => "Wine", :suggested_items => ["Merlot","Zinfadel", "Cabernet Sauvignon"], :new_or_existing => "New", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			@suggestion.save

			@suggestion = Suggestion.new(:category => "Wine", :suggested_items => ["Ice Wine","Petit Verdot"], :new_or_existing => "New", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@suggestion).to_not be_valid
			@suggestion.category = "Dessert Wine"
			expect(@suggestion).to be_valid
		end
	end

	describe "requesting additional items for existing list" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@guest = Attendee.create(:event_id => @event.id, :rsvp => "going", :email => "guest.person@gmail.com", :full_name => "ba barracus")
			@existing_list = PotluckItem.create(:event_id => @event.id, :category => "Appetizers", :host_quantity => 1, :dishes => [{"item" => "Nachos", "quantity" => 1},{"item" => "Buffalo Wings", "quantity" => 1},{"item" => "Taquitos", "quantity" => 1}])
		end

		it "should not suggest existing items to an existing list" do
			@suggestion = Suggestion.new(:category => "Appetizers", :suggested_items => ["Nachos", "fries"], :new_or_existing => "Existing", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)

			expect(@suggestion).to_not be_valid
			@suggestion.suggested_items[0] = "nachos"
			expect(@suggestion).to_not be_valid
			@suggestion.suggested_items[0] = "sliders"
			expect(@suggestion).to be_valid
		end

		it "should not allow an empty suggestion list for an existing category" do
			@suggestion = Suggestion.new(:category => "Appetizers", :suggested_items => [], :new_or_existing => "Existing", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@suggestion).to_not be_valid
		end

		it "should not allow for duplicates in the suggested items" do
			@suggestion = Suggestion.new(:category => "Appetizers", :suggested_items => ["Sliders","sliders"], :new_or_existing => "Existing", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@suggestion).to_not be_valid

			@suggestion.suggested_items[1] = "Potato Skins"
			@suggestion.save

			@other_suggestion = Suggestion.new(:category => "Appetizers", :suggested_items => ["Sliders","Peanuts"], :new_or_existing => "Existing", :event_id => @event.id, :requester_name => @guest.full_name, :requester_email => @guest.email)
			expect(@other_suggestion).to_not be_valid
		end
	end
end
