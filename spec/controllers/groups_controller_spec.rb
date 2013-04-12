require 'spec_helper'
require "devise/test_helpers"

describe GroupsController do

	def login
		@request.env["devise.mapping"] = Devise.mappings[:user]
		@user = FactoryGirl.create(:user,:email=>"testperson@gmail.com")
		sign_in @user
	end

  describe "GET index" do
		before(:all) do 
			User.destroy_all
			@user = FactoryGirl.create(:user)
			@bob = FactoryGirl.create(:bob)

			Group.create(:user_id => @user.id, :name=>"Test emails", :email_distribution_list => @bob.email)
			Group.create(:user_id => @bob.id, :name=>"Bob's emails", :email_distribution_list => @user.email)
		end

    it "should not allow users to view groups that do not belong to them" do
			login
			get 'index', :user_id => @bob.id

			response.should render_template(:file => "#{Rails.root}/public/401.html")
			response.status.should == 401
    end

    it "should allow users to view groups that do belong to them" do
			login
			get 'index', :user_id => @user.id

			response.should render_template(:file => "#{Rails.root}/views/groups/index.html.erb")
#			response.status.should == 200
    end
  end
end
