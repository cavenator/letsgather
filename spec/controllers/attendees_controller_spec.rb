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

	describe "RSVP for Guests" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		it "should allow guests to rsvp" do
			@request.env["devise.mapping"] = Devise.mappings[:user]
			@rico = FactoryGirl.create(:rico)
			@attendee = FactoryGirl.create(:attendee, :user_id => @rico.id, :email => @rico.email )
			@event = @attendee.event
			sign_in @rico
			Attendee.stub(:find).and_return(@attendee)
			@attendee.stub(:rsvp).and_return('Going')

			post 'rsvp', :event_id=> @event.id, :id => @attendee.id
		end
	end
end
