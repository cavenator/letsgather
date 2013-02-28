require 'spec_helper'

describe PotluckItem do
  describe "retrieving data for the guest" do
		before(:all) do

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

		it "should not allow a potluck item to be created if dishes are null" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Boardgames", :host_quantity => 2, :dishes => [])
			expect(@potluck_item).to_not be_valid
		end

		it "should allow empty dishes after initial create" do
			@potluck_item = PotluckItem.create(:event_id => @event.id, :category => "Desserts", :host_quantity => 2, :dishes => ["Brownies","Cookies"])
			expect(@potluck_item).to be_valid

			@potluck_item.dishes.clear
			expect(@potluck_item).to be_valid
		end
	end
end
