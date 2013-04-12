require 'spec_helper'
require "devise/test_helpers"

describe AttendeesController do
		include Devise::TestHelpers

	def login
		@request.env["devise.mapping"] = Devise.mappings[:user]
		@user = FactoryGirl.create(:user,:email=>"testperson@gmail.com")
		sign_in @user
	end

	describe "GET add_attendees" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
		end

		after(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "provides an area to add guests" do
			login
			get 'add_attendees', :event_id => @event.id
		end
	end

	describe "Host emailing attendee" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@user = @event.user
			Role.create(:user_id => @user.id, :event_id => @event.id, :privilege => "host")
			@attendee = FactoryGirl.create(:attendee, :event_id => @event.id)
		end

		it "should be able to send individual emails to attendee" do
			@request.env["devise.mapping"] = Devise.mappings[:user]
			sign_in @user

			get 'email_guest', :event_id => @event.id, :id => @attendee.id
			response.status.should == 200
		end
	end
end
