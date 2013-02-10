require 'spec_helper'

describe Attendee do

	describe "attendee minimal requirements" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		after(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		it "should have an email, event_id, and rsvp at a minimum" do
			attendee = Attendee.new
			expect(attendee).to_not be_valid
			attendee.email = "person@gmail.com"
			attendee.event_id = 12
			expect(attendee).to_not be_valid
		end

		it "should have rsvp status of 'Going', 'Not Going', or 'Undecided'" do
			attendee = FactoryGirl.build(:attendee, :rsvp => 'Bringing it', :email =>'random.person@gmail.com')
			expect(attendee).to_not be_valid
		end

		it "should have a distinct email per event" do
			attendee = FactoryGirl.create(:attendee)
			expect(Attendee.all.count) == 1
			attendee2 = FactoryGirl.build(:attendee, :event_id => attendee.event_id, :email => attendee.email )
			expect(attendee2).to_not be_valid
		end
	end

	describe "sending invites to guests" do

		before(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		after(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		describe "email validation" do
			it "finds a good email" do
				expect("alpha@gmail.com") =~ /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i
			end
			it "doesnt find bad emails" do
				expect("streetfighter@hairbringiner").to_not match(/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i)
			end
		end

		it "should provide a list of successful attendees" do
			expect(Attendee.all.count) == 0
			event = FactoryGirl.create(:event)
			invites = Attendee.invite(["person@gmail.com","person2@yahoo.com"], event)
			expect(Attendee.all.count) == 2
			expect(invites["successful"].count) == 2

			first_person = Attendee.find_by_email("person@gmail.com")
			first_person.rsvp.should eq "Undecided"
			expect(first_person.event_id) == event.id
		end

		it "should also provide a list of failed attendees" do
			event = FactoryGirl.create(:event)
			invites = Attendee.invite(["whatever","whythis@jeez"], event)
			expect(Attendee.all.count) == 0
			expect(invites["unsuccessful"].count) == 2
		end

		it "should not send out duplicates" do
			event = FactoryGirl.create(:event)
			invites = Attendee.invite(["sameperson@gmail.com","samperson@gmail.com"], event)
			expect(Attendee.all.count) == 1
			expect(invites["successful"].count) == 1
		end
	end

	describe "Attendee fetching" do
		before(:all) do
			User.destroy_all

			@user = FactoryGirl.create(:rico)
			@attendee = FactoryGirl.create(:attendee, :user_id => @user.id, :email => @user.email)
			@event = @attendee.event
		end

		after(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		it "should be able to find guests' attendee record" do
			expect(Attendee.find_attendee_for(@user, @event)).to eql(@attendee)
		end

		it "should be able to fetch the rsvp for an attendee" do
			expect(Attendee.find_rsvp_for(@user, @event)).to eql("Undecided")
		end
	end

	describe "Attendee RSVP" do

		before(:each) do
			User.destroy_all
			Event.destroy_all

			@attendee = FactoryGirl.build(:attendee)
		end

		it "should be allowed to have both a blank category and dish if custom is not selected" do
			expect(@attendee).to be_valid
		end

		it "should verify that dish is not empty if bringing a custom dish" do
			@attendee.bringing_custom = true
			@attendee.category = "Salads"
			expect(@attendee).to_not be_valid
			expect(@attendee.errors["dish"][0]).to eql("should not be empty if bringing custom dish")
			@attendee.dish = "Potato Salad"
			expect(@attendee).to be_valid
		end

		it "should verify that category is not null when bringing a custom dish" do
			@attendee.bringing_custom = true
			@attendee.dish = "Pizza"
			expect(@attendee).to_not be_valid
			@attendee.category = "Main Dish"
			expect(@attendee).to be_valid
		end
	end

	describe "Removing Guests" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@event = FactoryGirl.create(:event)
			@bob = FactoryGirl.create(:bob)
			@attendee = Attendee.create(:event_id => @event.id, :user_id => @bob.id, :rsvp => "Going", :email => @bob.email)
			Role.create(:user_id => @bob.id, :event_id => @event.id, :privilege => "guest")
		end

		it "should remove the role(s) from the event" do
			Attendee.destroy(@attendee)
			expect(Role.where("user_id = ? and event_id = ?",@bob.id,@event.id).count).to eql(0)
		end
	end
end
