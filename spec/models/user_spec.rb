require 'spec_helper'

describe User do
	describe "basic user profile" do

		before(:all) do
			User.destroy_all
		end

		after(:all) do
			User.destroy_all
		end

		it "should have at a bare minimum a first name, last name,  email and password" do
			user = FactoryGirl.create(:user, :first_name=>'Jake', :last_name=>'Wooley')
			expect(User.all.count).to eql(1)
		end

		it "should never have a blank email when modifying the account" do
			user = FactoryGirl.build(:user, :email => nil)
			expect(user).to_not be_valid
			user.save
			user.should have(1).error_on(:email)
		end

		it "should never have a blank first name" do
			user = FactoryGirl.build(:user, :first_name => nil)
			expect(user).to_not be_valid
			user.save
			user.should have(1).error_on(:first_name)
		end

		it "should never have a blank last name" do
			user = FactoryGirl.build(:user, :last_name => nil, :email => "example@gmail.com")
			expect(user).to_not be_valid
			user.save
			user.should have(1).error_on(:last_name)
		end
	end

	describe "roles for a user" do
		before(:all) do
			@user = FactoryGirl.create(:user, :first_name => "Rico", :last_name => "Suave")
			@event = FactoryGirl.create(:event, :name=>'Sedation', :start_date => 7.days.from_now, :rsvp_date => 5.days.from_now)
		end

		after(:all) do
			User.destroy_all
		end

		it "should inform the user if they are the host to the event" do
			expect(@user.is_host_for?(@event)) == true
		end

		it "should inform the user if they are a guest to an event" do

		end
	end

	describe "authorization of events" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should determine if a user is associated with the event" do
			@event = FactoryGirl.create(:event)
			@user = @event.user
			@rico = FactoryGirl.create(:rico)
			expect(@user.belongs_to_event?(@event)) == true
			expect(@rico.belongs_to_event?(@event)) == false
		end
	
		after(:all) do
			User.destroy_all
			Event.destroy_all
		end

	end

	describe "User account deletion" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should remove that person from events they are invited to" do
			@event = FactoryGirl.create(:event)
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)

			Attendee.create(:event_id => @event.id, :user_id => @bob.id, :rsvp => "Going", :email => @bob.email)
			Attendee.create(:event_id => @event.id, :user_id => @rico.id, :rsvp => "Not Going", :email => @rico.email)

			expect(Attendee.all.count) == 2

			@bob.destroy

			expect(User.all.count) == 2
			expect(Attendee.where("event_id = ?", @event.id).count) == 1
		end
	end
end
