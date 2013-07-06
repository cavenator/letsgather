require 'spec_helper'
require "devise/test_helpers"

describe SuggestionsController do

  def valid_attributes_per(event)
    { :new_or_existing => "New", :event_id => event.id, :category => "Sides", :suggested_items => ["Fries","Mashed Potatoes", "Baked Beans","Salad"], :requester_name => "Test Person", :requester_email => "test.person@gmail.com" }
  end

  def valid_session
    {}
  end

	def login_for_user(user)
		@request.env["devise.mapping"] = Devise.mappings[:user]
		sign_in user
	end

  describe "GET index" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@user = @event.user
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)
			Role.create(:event_id => @event.id, :user_id => @bob.id, :privilege => "guest")
		end

    it "should only hosts/guests to see index page" do
			login_for_user(@user)
      get :index, :event_id => @event.id
			response.status.should == 200

			login_for_user(@bob)
			get :index, :event_id => @event.id
			response.status.should == 200
    end
    it "should prohibit unauthorized guests to see index page" do
			login_for_user(@rico)
      get :index, :event_id => @event.id
			response.status.should == 401
    end
  end

  describe "GET new" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@user = @event.user
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)
			Role.create(:event_id => @event.id, :user_id => @bob.id, :privilege => "guest")
		end

    it "should only allow guests to get to the new suggestions page" do
			login_for_user(@bob)
      get :new, :event_id => @event.id
      assigns(:suggestion).should be_a_new(Suggestion)
			expect(response.status) == 200
    end

    it "should prohibit hosts from getting to the new suggestions page" do
			login_for_user(@user)
      get :new, :event_id => @event.id
			response.status.should == 401
    end

    it "should prohibit unauthorized guests from getting to the new suggestions page" do
			login_for_user(@rico)
      get :new, :event_id => @event.id
			response.status.should == 401
    end
  end

  describe "POST create" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@user = @event.user
			@bob = FactoryGirl.create(:bob)
			@rico = FactoryGirl.create(:rico)
			Role.create(:event_id => @event.id, :user_id => @bob.id, :privilege => "guest")
		end

    describe "with valid params" do
      it "creates a new Suggestion for a authorized guest" do
				login_for_user(@bob)
        expect {
          post :create, {:event_id => @event.id, :suggestion => valid_attributes_per(@event)}
        }.to change(Suggestion, :count).by(1)
				response.status.should == 201
      end

      it "prohibits a host from making a suggestion" do
				login_for_user(@user)
        expect {
          post :create, {:event_id => @event.id, :suggestion => valid_attributes_per(@event)}
        }.to change(Suggestion, :count).by(0)
				response.status.should == 401
      end
    end
  end

end
