require 'spec_helper'
require "devise/test_helpers"

describe EventsController do
	include Devise::TestHelpers

	def login
		@request.env["devise.mapping"] = Devise.mappings[:user]
		@user = FactoryGirl.create(:user,:email=>"testperson@gmail.com")
		sign_in @user
	end

	def login_for_bob
		@request.env["devise.mapping"] = Devise.mappings[:user]
		sign_in @bob
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
			Role.destroy_all
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

	describe "unauthorized handling" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
		end

		it "should only allow users to access their events or events they are invited to only" do
			@event = FactoryGirl.create(:event_secondary)
			Role.create(:user_id => @event.user.id, :event_id => @event.id, :privilege => "host")
			login
			get 'show', :id => @event.id
			response.should render_template(:file => "#{Rails.root}/public/401.html")
			response.status.should == 401
		end

		it "should ensure that attendees that have been removed from the event should not be allowed" do
			@event = FactoryGirl.create(:event)
			@bob = FactoryGirl.create(:bob)
			attendee = Attendee.create(:event_id => @event.id, :user_id => @bob.id, :rsvp => "Going", :email => @bob.email)
			Role.create(:user_id => @bob.id, :event_id => @event.id, :privilege => "guest")

			Attendee.destroy(attendee)
			login_for_bob
			get 'show', :id => @event.id
			response.should render_template(:file => "#{Rails.root}/public/401.html")
			response.status.should == 401
		end
	end

	describe "emailing capabilities" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			Role.create(:user_id => @event.user.id, :event_id => @event.id, :privilege => "host")
			@attendees = []
			@attendees << FactoryGirl.create(:attendee, :event_id => @event.id)
			@attendees << FactoryGirl.create(:attendee, :event_id => @event.id)
		end

		it "should be able to email an entire group" do
			@request.env["devise.mapping"] = Devise.mappings[:user]
			sign_in @event.user
	
			get 'group_email', :id => @event.id
			response.status.should == 200
		end
	end
end
