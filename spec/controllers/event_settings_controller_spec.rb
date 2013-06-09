require 'spec_helper'
require "devise/test_helpers"

describe EventSettingsController do
	def login
		@request.env["devise.mapping"] = Devise.mappings[:user]
		@user = FactoryGirl.create(:user,:email=>"testperson@gmail.com")
		sign_in @user
	end

  describe "GET index" do
		before(:all) do 
			User.destroy_all
			@event = FactoryGirl.create(:event)
			@event2 = FactoryGirl.create(:event_secondary)
			@user = @event.user
			@rico = @event2.user
		end

    it "should not allow users to view groups that do not belong to them" do
			login
			get 'get_settings', :user_id => @rico.id

			response.should render_template(:file => "#{Rails.root}/public/401.html")
			response.status.should == 401
    end

    it "should allow users to view groups that do belong to them" do
			login
			get 'get_settings', :user_id => @user.id

			response.should render_template(:file => "#{Rails.root}/views/event_settings/index.html.erb")
			response.status.should == 200
    end
  end

end
