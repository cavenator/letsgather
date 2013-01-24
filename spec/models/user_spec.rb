require 'spec_helper'

describe User do
	describe "basic user profile" do

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
			@role = Role.create(:user_id => @user.id, :event_id => @event.id, :privilege => "host")
		end

		after(:all) do
			User.destroy_all
		end

		it "should be able to find the appropriate role for an actual host" do
			expect(@user.find_role_for(@event)).to eql("host")
		end

		it "should inform the user if they are the host to the event" do
			expect(@user.is_host_for?(@event)) == true
		end
	end
end
