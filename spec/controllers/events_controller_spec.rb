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

		it "should redirect back to event once the email has been sent" do
			@request.env["devise.mapping"] =  Devise.mappings[:user]
			sign_in @event.user

			get 'send_group_email', :id => @event.id, :subject =>"Something here", :body => "body goes here", :rsvp_group => "Undecided"
			response.should redirect_to(:action => 'show')
		end

		it "should redirect back to drafting email if the subject or body is blank" do
			@request.env["devise.mapping"] =  Devise.mappings[:user]
			sign_in @event.user

			get 'send_group_email', :id => @event.id, :subject =>"", :body => "body goes here"
			response.should redirect_to(:action => 'group_email')
		end
	end

	describe "Guest emailing host capabilities" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			Role.create(:user_id => @event.user.id, :event_id => @event.id, :privilege => "host")

			@bob = FactoryGirl.create(:bob)
			Attendee.create(:full_name => @bob.full_name, :event_id=>@event.id, :user_id => @bob.id, :email => @bob.email, :rsvp => "Going")
			Role.create(:user_id => @bob.id, :event_id => @event.id, :privilege => "guest")
		end

		it "should allow guests to email the host" do
			login_for_bob
			get 'email_host', :id => @event.id
			response.status.should == 200
		end

		it "should redirect you back to guest event page if sent correctly" do
			login_for_bob
			get 'send_host_email', :id => @event.id, :subject => "Something something", :body => "I am a message"
			response.status.should == 302
			response.should redirect_to(:action => :show)
		end

		it "should take you back to emailing draft page if subject or body is empty" do
			login_for_bob
			get 'send_host_email', :id => @event.id
			response.should redirect_to(:action => :email_host)
		end
	end
end
