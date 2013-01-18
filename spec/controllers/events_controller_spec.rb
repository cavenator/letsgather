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
		end

		after(:all) do
			User.destroy_all
		end
	end

end
