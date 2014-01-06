require 'spec_helper'

describe PotluckItem do
  describe "retrieving data for the guest" do
		before(:each) do

			User.destroy_all
			Event.destroy_all
			PotluckItem.destroy_all

			@event = FactoryGirl.create(:event)
			PotluckItem.create(:event_id => @event.id, :category => "Beer", :dishes => [{ "item" => "IPA", "quantity" => 2 },{ "item" => "Pale Ale", "quantity" => 1 }], :host_quantity=>1 )
			PotluckItem.create(:event_id => @event.id, :category => "Appetizers", :dishes => [{"item" => "Nachos", "quantity" => 1},{ "item" => "Buffalo Wings", "quantity" => 3 },{"item" => "Spring Rolls", "quantity" => 6 }], :host_quantity=>2)
		end

		it "should get all of the categories and items per list" do
			@potluck_items = @event.get_potluck_items_for_guests
			expect(@potluck_items.count) == 2
			expect(@potluck_items[0]).to eql({"category" => "Beer", "dishes" => [{ "item" => "IPA", "quantity" => 2 },{ "item" => "Pale Ale", "quantity" => 1 }]})
			expect(@potluck_items[1]).to eql({"category" => "Appetizers", "dishes" => [{"item" => "Nachos", "quantity" => 1},{ "item" => "Buffalo Wings", "quantity" => 3 },{"item" => "Spring Rolls", "quantity" => 6 }]})
		end

		it "should allow a potluck list to be created if no items specified with category" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Boardgames", :host_quantity => 2, :dishes => [])
			expect(@potluck_item).to be_valid
		end

		it "should allow empty dishes after initial create" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => [{ "item" => "Brownies", "quantity" => 1 },{ "item" => "Cookies", "quantity" => 6 }])
			expect(@potluck_item).to be_valid

			@potluck_item.dishes.clear
			expect(@potluck_item).to be_valid
		end

		it "should not allow duplicate dishes within the same category upon create" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Desserts", :host_quantity => 1, :dishes => [{"item" => "Brownies", "quantity" => 2},{"item" => "Brownies", "quantity" => 1},{"item" => "Cookies", "quantity" => 10}])
			expect(@potluck_item).to_not be_valid
		end

		it "should not allow duplicate dishes within the same category upon update" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => [{ "item" => "Brownies", "quantity" => 3 },{"item" => "Cookies", "quantity" => 10}])
			expect(@potluck_item).to be_valid

			@potluck_item.dishes << {"item" => "Brownies", "quantity" => 1 }
			expect(@potluck_item).to_not be_valid

			@potluck_item.dishes = [{ "item" => "Brownies", "quantity" => 3 },{"item" => "Cookies", "quantity" => 10}, {"item" => "Cupcakes", "quantity" => 6 }]
			expect(@potluck_item).to be_valid
		end

		it "should not be allowed to delete potluck items if any of the items is taken" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => [{ "item" => "Brownies", "quantity" => 3 },{"item" => "Cookies", "quantity" => 10}])
			expect(@potluck_item).to be_valid

			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"guests" => [attendee.id], "item" => "Brownies" }
			@potluck_item.dishes.find{|a| a["item"] == "Brownies" }["quantity"] = 0
			@potluck_item.save

			@potluck_item = PotluckItem.find(@potluck_item.id)
			@potluck_item.destroy

			expect(PotluckItem.where("event_id = ?",@event.id).count).to eql(3)
		end

		it "should not be allowed to remove any dishes if they are rsvped (taken) by guest" do
			@potluck_item = PotluckItem.find_by_category("Beer")
			
			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"guests"=> [attendee.id], "item" => "IPA" }
			@potluck_item.dishes.delete_if { |a| a["item"].eql?("IPA") }
			expect(@potluck_item).to_not be_valid
		end

		it "should be allowed to update the quantity number if guests rsvp with a portion of it" do
			@potluck_item = PotluckItem.find_by_category("Beer")
			
			#simulate guest rsvping with an item; refactor to do via a method call
			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"guests" => attendee.id, "item" => "IPA" }
			@potluck_item.dishes.find{|a| a["item"] == "IPA" }["quantity"] = 1
			@potluck_item.save

			#edit the quantity for IPA
			@potluck_item.dishes.find{ |a| a["item"] == "IPA" }["quantity"] = 3
			expect(@potluck_item).to be_valid
		end

		it "should not have any available items with a quantity less than 0" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Desserts", :host_quantity => 1, :dishes => [{"item" => "Brownies", "quantity" => 2},{"item" => "Cookies", "quantity" => -1 }])
			expect(@potluck_item).to_not be_valid
		end
	end

	describe "Potluck Items Merge Deltas" do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			PotluckItem.destroy_all
			@event = FactoryGirl.create(:event)
			@attendee = FactoryGirl.create(:attendee, :event_id => @event.id)
		end

		it "should be able to merge empty lists" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 2},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])

			PotluckItem.mergeDeltasAndUpdateIfNecessary([], @event, @attendee.id)
			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 2},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(actual_potluck_item.taken_items).to eq([])
		end

		it "should be able to merge deltas of a first rsvp" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 2},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])

			PotluckItem.mergeDeltasAndUpdateIfNecessary([{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Stout", "quantity" => 1, "is_custom" => false}], @event, @attendee.id)

			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0}])
			expect(actual_potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [@attendee.id]},{"item" => "Stout", "guests" => [@attendee.id]}])
		end

		it "should be able to merge deltas of another guests who rsvps an already rsvped item" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}], :taken_items => [{"item" => "IPA", "guests" => [0]}])

			PotluckItem.mergeDeltasAndUpdateIfNecessary([{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Stout", "quantity" => 1, "is_custom" => false}], @event, @attendee.id)

			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0}])
			expect(actual_potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [0, @attendee.id]},{"item" => "Stout", "guests" => [@attendee.id]}])
		end

		it "should be able to merge deltas if guests remove an item from their rsvp" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1 }], :taken_items => [{"item" => "IPA", "guests" => [0, @attendee.id]}])

			PotluckItem.mergeDeltasAndUpdateIfNecessary([{"category" => "Beer", "item" => "IPA", "quantity" => -1, "is_custom" => false, "removed" => true}], @event, @attendee.id)

			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(actual_potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [0]}])
		end

		it "should remove the entry in the taken_items if the guests array is blank" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1 }], :taken_items => [{"item" => "IPA", "guests" => [ @attendee.id]}])

			PotluckItem.mergeDeltasAndUpdateIfNecessary([{"category" => "Beer", "item" => "IPA", "quantity" => -1, "is_custom" => false, "removed" => true}], @event, @attendee.id)

			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(actual_potluck_item.taken_items).to eq([])
		end

		it "should put delta in unapplied deltas return if quantity sum is less than 0" do

			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 2 },{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1 }], :taken_items => [])
			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false }, {"category" => "Beer", "item" => "Red Ale", "quantity" => 2, "is_custom" => false}]
			unapplied_deltas = PotluckItem.mergeDeltasAndUpdateIfNecessary([{"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false }, {"category" => "Beer", "item" => "Red Ale", "quantity" => 2, "is_custom" => false}], @event, @attendee.id)

			actual_potluck_item = PotluckItem.find(@potluck_item.id)
			expect(actual_potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 0 },{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(actual_potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [@attendee.id]}])
			expect(unapplied_deltas).to eq([{"category" => "Beer", "item" => "Red Ale", "quantity" => 2, "is_custom" => false }])
		end
	end

	describe "Make potluck items available" do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@attendee = FactoryGirl.create(:attendee, :event_id => @event.id)
		end

		it "remove the guest reference from taken_items" do
			@beer_items = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0 }], :taken_items => [{"item" => "IPA", "guests" => [0, @attendee.id]},{"item" => "Stout", "guests" => [0, @attendee.id]}])
			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Stout", "quantity" => 1, "is_custom" => false}]
			PotluckItem.make_items_available(@attendee, @event)

			@potluck_item = PotluckItem.find(@beer_items.id)
			expect(@potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(@potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [0]},{"item" => "Stout", "guests" => [0]}])
		end

		it "remove taken_item from taken_items_index if no guests have rsvped them" do
			@beer_items = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0 }], :taken_items => [{"item" => "IPA", "guests" => [ @attendee.id]},{"item" => "Stout", "guests" => [ @attendee.id]}])

			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Stout", "quantity" => 1, "is_custom" => false}]
			PotluckItem.make_items_available(@attendee, @event)

			@potluck_item = PotluckItem.find(@beer_items.id)
			expect(@potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(@potluck_item.taken_items).to eq([])
		end

		it "should do nothing with custom items" do
			@beer_items = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1 }], :taken_items => [{"item" => "IPA", "guests" => [ @attendee.id]}])

			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Porter", "quantity" => 1, "is_custom" => true }]
			PotluckItem.make_items_available(@attendee, @event)

			@potluck_item = PotluckItem.find(@beer_items.id)
			expect(@potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 1},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 1}])
			expect(@potluck_item.taken_items).to eq([])
		end

		it "should not do anything if guest dish selection is empty" do
			@beer_items = PotluckItem.create(:event_id => @event.id, :category => "Beer", :host_quantity => 2, :dishes => [{"item" => "IPA", "quantity" => 0},{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0 }], :taken_items => [{"item" => "IPA", "guests" => [0]},{"item" => "Stout", "guests" => [0]}])
			@attendee.dish = []
			PotluckItem.make_items_available(@attendee, @event)

			@potluck_item = PotluckItem.find(@beer_items.id)
			expect(@potluck_item.dishes).to eq([{"item" => "IPA", "quantity" => 0 },{"item" => "Red Ale", "quantity" => 1}, {"item" => "Stout", "quantity" => 0}])
			expect(@potluck_item.taken_items).to eq([{"item" => "IPA", "guests" => [0]},{"item" => "Stout", "guests" => [0]}])
		end
	end
end
