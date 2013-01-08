require 'spec_helper'

describe InventoryCount do
	describe "minimal requirements" do
		it "should have all values default to zero" do
			inventory = FactoryGirl.create(:inventory_count)
			expect(inventory.app_count) == 0
			expect(inventory.main_dish_count) == 0
			expect(inventory.salads_count) == 0
			expect(inventory.sides_count) == 0
			expect(inventory.desserts_count) == 0
			expect(inventory.drinks_count) == 0
			expect(inventory.event).to be_valid
		end

		it "should only have numeric values" do
			inventory = FactoryGirl.build(:inventory_count, :app_count => 'hello')
			expect(inventory).to_not be_valid
			inventory.app_count = 9
			expect(inventory).to be_valid
		end
	end
end
