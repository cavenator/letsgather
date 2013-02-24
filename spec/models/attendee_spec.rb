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
			@event = @attendee.event
			@rico_suave = FactoryGirl.create(:rico)
			@bob = FactoryGirl.create(:bob)
			@potluck_items = FactoryGirl.create(:potluck_item, :event_id => @event.id)
			@rico_attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :user_id => @rico_suave.id, :email => @rico_suave.email, :rsvp => "Going")
			@bob_attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :user_id => @bob.id, :email => @bob.email, :rsvp => "Going")
		end

		it "should be allowed to have an empty dish selection" do
			expect(@attendee).to be_valid
		end

		it "should verify that neither category nor item is blank" do
			@attendee.dish = [{ "category"=> "Beer", "item" => "IPA", "is_custom" => false },{ "category"=> "Snacks","item"=>"Doritos Nacho Cheese", "is_custom" => true }]
			expect(@attendee).to be_valid
			@attendee.dish[1] = {"category"=>"", "item" => "Something", "is_custom"=>true}
			expect(@attendee).to_not be_valid
			@attendee.dish.delete(@attendee.dish.last)
			expect(@attendee).to be_valid
			@attendee.dish << {"category" => "Beer", "item" => "", "is_custom" => false }
			expect(@attendee).to_not be_valid
			@attendee.dish = []
			expect(@attendee).to be_valid
		end

		describe "Item re-arrangement" do
			it "should verify if an item is available for the taking, mark it as taken" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "is_custom" => false}]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
		
				expect(refreshed_list.taken_items).to eql([{"id"=>@rico_attendee.id,"item" => "Brown Ale"}])
				expect(refreshed_list.dishes).to eql(["Stout", "IPA", "Pale Ale"])

				@rico_attendee.dish = []
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql(["Stout","IPA","Pale Ale","Brown Ale"])
				expect(refreshed_list.taken_items).to be_blank
			end

			it "should reset the available items back if attendee does not attend or is undecided" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "is_custom" => false},{"category" => "Beer", "item" => "Pliny the Younger", "is_custom" => true }]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
		
				expect(refreshed_list.taken_items).to eql([{"id"=>@rico_attendee.id,"item" => "Brown Ale"}])
				expect(refreshed_list.dishes).to eql(["Stout", "IPA", "Pale Ale"])

				@rico_attendee.rsvp = "Not Going"
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(@rico_attendee.rsvp).to eql("Not Going")
				expect(refreshed_list.dishes).to eql(["Stout","IPA","Pale Ale","Brown Ale"])
				expect(refreshed_list.taken_items).to eql([])
			end

			it "should remain constant if guest just changes comment or guest count, not items"
		end

		describe "Taken items validation" do
			it "should not be valid if you are choosing an item that has been selected" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "is_custom" => false}]
				@rico_attendee.save

				@bob_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "is_custom" => false}]
				expect(@bob_attendee).to_not be_valid
			end
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
