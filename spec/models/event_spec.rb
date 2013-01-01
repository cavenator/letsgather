require 'spec_helper'

describe Event do

	describe "user minimum requirements before creating event" do
		it "should check to ensure that a user has an email" do
			event = FactoryGirl.create(:event)
			Event.should have(1).record
			User.should have(1).record
			expect(event.user.first_name).to eql("Alice")
		end
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
	end
end
