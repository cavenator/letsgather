require 'spec_helper'

describe PotluckItem do
  describe "retrieving data for the guest" do
		before(:each) do

			User.destroy_all
			Event.destroy_all

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
			@potluck_item.taken_items << {"id" => attendee.id, "item" => "Brownies", "quantity" => 3 }
			@potluck_item.dishes.find{|a| a["item"] == "Brownies" }["quantity"] = 0
			@potluck_item.save

			@potluck_item = PotluckItem.find(@potluck_item.id)
			@potluck_item.destroy

			expect(PotluckItem.where("event_id = ?",@event.id).count).to eql(3)
		end

		it "should not be allowed to remove any dishes if they are rsvped (taken) by guest" do
			@potluck_item = PotluckItem.find_by_category("Beer")
			
			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"id" => attendee.id, "item" => "IPA", "quantity" => 1 }
			@potluck_item.dishes.delete_if { |a| a["item"].eql?("IPA") }
			expect(@potluck_item).to_not be_valid
		end

		it "should be allowed to update the quantity number if guests rsvp with a portion of it" do
			@potluck_item = PotluckItem.find_by_category("Beer")
			
			#simulate guest rsvping with an item; refactor to do via a method call
			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"id" => attendee.id, "item" => "IPA", "quantity" => 1 }
			@potluck_item.dishes.find{|a| a["item"] == "IPA" }["quantity"] = 1
			@potluck_item.save

			#edit the quantity for IPA
			@potluck_item.dishes.find{ |a| a["item"] == "IPA" }["quantity"] = 3
			expect(@potluck_item).to be_valid
		end
	end
end
