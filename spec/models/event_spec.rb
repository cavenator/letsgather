require 'spec_helper'

describe Event do


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
		it "should check to ensure that a user has an email" do
			event = FactoryGirl.create(:event)
			Event.should have(1).record
			User.should have(1).record
			expect(event.user.email).to eql("alice.cooper@gmail.com")
		end

		it "should create an Inventory Count object after create" do
			event = FactoryGirl.create(:event)
			expect(event.inventory_count).to be_valid
		end
	end

end