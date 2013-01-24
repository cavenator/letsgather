require 'spec_helper'
require "devise/test_helpers"

describe EventsController do
	include Devise::TestHelpers

	def login
		@request.env["devise.mapping"] = Devise.mappings[:user]
		@user = FactoryGirl.create(:user,:email=>"testperson@gmail.com")
		sign_in @user
	end
	context "list of events index page" do

		it "should be able to see list of created events" do
			login
			get 'index'
		end

		it "should be able to create new event" do
			login
			event = mock_model(Event)
			Event.stub(:new).and_return(event)
			get 'new'
			response.should be_success
		end

		it "should be able to save an event" do
			login
			event = mock_model(Event)
			event.stub(:new).with("name" => "Sample Event", "start_date" => 7.days.from_now, "rsvp_date" => 5.days.from_now).and_return(event)
			event.stub(:save)
			post 'create'
		end

		after(:all) do
			User.destroy_all
			Event.destroy_all
			Host.destroy_all
		end
	end

	describe "showing events with roles involved" do
		it "should show the correct view for a host" do
			login
			@event = FactoryGirl.create(:event, :user_id => @user.id)
			@host = Role.create(:user_id => @user.id, :event_id => @event.id, :privilege => "host")

			get 'show', :id => @event.id
		end
	end
end