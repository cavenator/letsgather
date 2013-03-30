require 'spec_helper'

describe PotluckItem do
  describe "retrieving data for the guest" do
		before(:each) do

			User.destroy_all
			Event.destroy_all

			@event = FactoryGirl.create(:event)
			PotluckItem.create(:event_id => @event.id, :category => "Beer", :dishes => ["IPA","Pale Ale"], :host_quantity=>1)
			PotluckItem.create(:event_id => @event.id, :category => "Appetizers", :dishes => ["Nachos","Buffalo Wings","Spring Rolls"], :host_quantity=>2)
		end

		it "should get all of the categories and items per list" do
			@potluck_items = @event.get_potluck_items_for_guests
			expect(@potluck_items.count) == 2
			expect(@potluck_items[0]).to eql({"category" => "Beer", "dishes" => ["IPA","Pale Ale"]})
			expect(@potluck_items[1]).to eql({"category" => "Appetizers", "dishes" => ["Nachos","Buffalo Wings","Spring Rolls"]})
		end

		it "should allow a potluck list to be created if no items specified with category" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Boardgames", :host_quantity => 2, :dishes => [])
			expect(@potluck_item).to be_valid
		end

		it "should allow empty dishes after initial create" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => ["Brownies","Cookies"])
			expect(@potluck_item).to be_valid

			@potluck_item.dishes.clear
			expect(@potluck_item).to be_valid
		end

		it "should not allow duplicate dishes within the same category upon create" do
			@potluck_item = PotluckItem.new(:event_id => @event.id, :category => "Desserts", :host_quantity => 1, :dishes => ["Brownies","Brownies","Cookies"])
			expect(@potluck_item).to_not be_valid
		end

		it "should not allow duplicate dishes within the same category upon update" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => ["Brownies","Cookies"])
			expect(@potluck_item).to be_valid

			@potluck_item.dishes << "Brownies"
			expect(@potluck_item).to_not be_valid

			@potluck_item.dishes = ["Cookies","Brownies","Cupcakes"]
			expect(@potluck_item).to be_valid
		end

		it "should not allow duplicate dishes within the same category upon update if duplicated item is within taken item" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => ["Brownies","Cookies"])
			expect(@potluck_item).to be_valid

			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"id" => attendee.id, "item" => "Brownies" }
			@potluck_item.dishes.delete("Brownies")
			@potluck_item.save

			@potluck_item = PotluckItem.find(@potluck_item.id)

			@potluck_item.dishes = ["Cookies","Brownies"]
			expect(@potluck_item).to_not be_valid
		end

		it "should not be allowed to delete potluck items if any of the items is taken" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => ["Brownies","Cookies"])
			expect(@potluck_item).to be_valid

			attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp => "Going")
			@potluck_item.taken_items << {"id" => attendee.id, "item" => "Brownies" }
			@potluck_item.dishes.delete("Brownies")
			@potluck_item.save

			@potluck_item = PotluckItem.find(@potluck_item.id)
			@potluck_item.destroy

			expect(PotluckItem.where("event_id = ?",@event.id).count).to eql(3)
		end
	end
end
