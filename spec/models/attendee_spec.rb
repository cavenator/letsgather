require 'spec_helper'

describe Attendee do

	describe "attendee minimal requirements" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
		end

		after(:each) do
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

		it "should not allow a host to register themselves as a guest" do
			event = FactoryGirl.create(:event)
			attendee = FactoryGirl.build(:attendee, :event_id => event.id, :email => event.user.email, :user_id => event.user.id)
			expect(attendee).to_not be_valid
		end

		it "should be allowed to have a blank email and be valid" do
			attendee = FactoryGirl.build(:attendee, :email=> nil)
			expect(attendee).to be_valid
		end

		it "should be allowed to have more than one person who has a blank email" do
			attendee = FactoryGirl.create(:attendee, :email=>nil)
			attendee2 = FactoryGirl.build(:attendee, :event_id => attendee.event_id ,:full_name=>"Jane Doe", :email=>nil)
			expect(attendee2).to be_valid
		end

		it "should be allowed to have a mixture of emails" do
			attendee = FactoryGirl.create(:attendee)
			attendee2 = FactoryGirl.create(:attendee, :event_id => attendee.event_id, :full_name=>"Jane Doe", :email => nil)
			attendee3 = FactoryGirl.build(:attendee, :event_id => attendee.event_id, :full_name=> "John Doe", :email => nil)
			expect(attendee3).to be_valid
			attendee3.save
			attendee4 = FactoryGirl.build(:attendee, :event_id=>attendee.event_id, :full_name=>"Somebody", :email => attendee.email)
			expect(attendee4).to_not be_valid
			attendee5 = FactoryGirl.build(:attendee, :event_id => attendee.event_id, :full_name => "Osmebody", :email => "somebody@gmail.com")
			expect(attendee5).to be_valid
			attendee6 = FactoryGirl.build(:attendee, :event_id => attendee.event_id, :full_name => "Ozzy Osbourne", :email => "ozzy")
			expect(attendee6).to_not be_valid
			attendee6.email = "ozzy.osbourne"
			expect(attendee6).to_not be_valid
			attendee6.email = "ozzy.osbourne@gmail"
			expect(attendee6).to_not be_valid
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
			invites = Attendee.invite(["person@gmail.com","person2@yahoo.com"], event, event.user)
			expect(Attendee.all.count) == 2
			expect(invites["successful"].count) == 2

			first_person = Attendee.find_by_email("person@gmail.com")
			expect(first_person.rsvp) == "No Response"
			expect(first_person.event_id) == event.id
		end

		it "should also provide a list of failed attendees" do
			event = FactoryGirl.create(:event)
			invites = Attendee.invite(["whatever","whythis@jeez"], event, event.user)
			expect(Attendee.all.count) == 0
			expect(invites["unsuccessful"].count) == 2
		end

		it "should not send out duplicates" do
			event = FactoryGirl.create(:event)
			invites = Attendee.invite(["sameperson@gmail.com","samperson@gmail.com"], event, event.user)
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
			expect(Attendee.find_rsvp_for(@user, @event)).to eql("You are currently a Maybe")
		end
	end

	describe "Deltas between attendee state" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			Attendee.destroy_all
			@settings = FactoryGirl.create(:setting)
			@event = @settings.event
			@attendee = Attendee.new(:event_id => @event.id, :full_name => "Rick", :email => "somedude@dude.com", :rsvp => "Going")
		end

		it "deltas when list is nil and attendee.dish has items" do
			@attendee.dish = [{"category" => "Dessert", "item" => "Chocolate Cookies", "is_custom" => false, "quantity" => 2}]
			deltas = @attendee.get_deltas_from_list([])
			expect(deltas) == ([{"category" => "Dessert", "item" => "Chocolate Cookies", "is_custom" => false, "quantity" => 2}])
		end

		it "deltas between same number of items between list - different quantities" do
			previous_items = [{"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => false}]

			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 5, "is_custom" => false }]
			deltas = @attendee.get_deltas_from_list(previous_items)
			expect(deltas[0]).to eq({"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false })
		end

		it "deltas when list has greater items than the guest and reduction of quantity" do
			previous_items = [{"category" => "Beer", "item" => "IPA", "quantity" => 5, "is_custom" => false}, {"category" => "Appetizers", "item"=>"Nachos", "quantity" => 1, "is_custom" => false}]

			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => false }]
			deltas = @attendee.get_deltas_from_list(previous_items)
			expect(deltas.count).to  eq(2)
			expect(deltas[0]).to eq({"category" => "Beer", "item" => "IPA", "quantity" => -2, "is_custom" => false })
			expect(deltas[1]).to eq({"category" => "Appetizers", "item" => "Nachos", "quantity" => -1, "is_custom" => false, "removed" => true })
		end

		it "deltas when list has custom items" do
			previous_items = [{"category" => "Beer", "item" => "IPA", "quantity" => 5, "is_custom" => true}, {"category" => "Appetizers", "item"=>"Nachos", "quantity" => 1, "is_custom" => false}]

			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => true }]
			deltas = @attendee.get_deltas_from_list(previous_items)
			expect(deltas.count).to  eq(1)
			expect(deltas[0]).to eq({"category" => "Appetizers", "item" => "Nachos", "quantity" => -1, "is_custom" => false, "removed" => true })
		end

		it "deltas when list has all custom items and new list has assigned item" do
			previous_items = [{"category" => "Beer", "item" => "IPA", "quantity" => 5, "is_custom" => true}, {"category" => "Appetizers", "item"=>"Nachos", "quantity" => 1, "is_custom" => true }]

			@attendee.dish = [{"category" => "Beer", "item" => "Amber Ale", "quantity" => 3, "is_custom" => false }]
			deltas = @attendee.get_deltas_from_list(previous_items)
			expect(deltas.count).to  eq(1)
			expect(deltas[0]).to eq({"category" => "Beer", "item" => "Amber Ale", "quantity" => 3, "is_custom" => false })
		end

		it "deltas when list has all rsvp items and new list has custom item" do
			previous_items = [{"category" => "Beer", "item" => "IPA", "quantity" => 5, "is_custom" => false}, {"category" => "Appetizers", "item"=>"Nachos", "quantity" => 1, "is_custom" => false }]

			@attendee.dish = [{"category" => "Beer", "item" => "Amber Ale", "quantity" => 3, "is_custom" => true }]
			deltas = @attendee.get_deltas_from_list(previous_items)
			expect(deltas.count).to  eq(2)
			expect(deltas[0]).to eq({"category" => "Beer", "item" => "IPA", "quantity" => -5, "is_custom" => false, "removed" => true})
			expect(deltas[1]).to eq({"category" => "Appetizers", "item"=>"Nachos", "quantity" => -1, "is_custom" => false, "removed" => true })
		end
	end

	describe "Unapplying deltas" do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			@attendee = FactoryGirl.create(:attendee)
		end

		it "should be able to unapply a delta" do
			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => false},{"category" => "Beer", "item" => "Red Ale", "quantity" => 1, "is_custom" => false}]

			@attendee.unapply_delta({"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false })
			expect(@attendee.dish.count).to eq(2)
			expect(@attendee.dish[0]).to eq({"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false})
		end

		it "should be able to remove a delta if necessary (quantity is 0)" do
			@attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => false},{"category" => "Beer", "item" => "Red Ale", "quantity" => 1, "is_custom" => false}]

			@attendee.unapply_delta({"category" => "Beer", "item" => "Red Ale", "quantity" => 1, "is_custom" => false })
			expect(@attendee.dish.count).to eq(1)
			expect(@attendee.dish[0]).to eq({"category" => "Beer", "item" => "IPA", "quantity" => 3, "is_custom" => false})
		end
	end

	describe "Attendee RSVP" do

		before(:each) do
			User.destroy_all
			Event.destroy_all
			@setting = FactoryGirl.create(:setting)
			@event = @setting.event
			@attendee = FactoryGirl.build(:attendee, :event_id => @event.id)
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
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "quantity"=> 1,"is_custom" => false}]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
		
				expect(refreshed_list.taken_items).to eql([{"guests"=>[@rico_attendee.id],"item" => "Brown Ale"}])
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity"=> 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2}, {"item" => "Brown Ale", "quantity" => 0}])

				@rico_attendee.dish = []
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity"=> 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2}, {"item" => "Brown Ale", "quantity" => 1}])
				expect(refreshed_list.taken_items).to be_blank
			end

			it "should reset the available items back if attendee does not attend or is undecided" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "Pliny the Younger", "is_custom" => true }]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
		
				expect(refreshed_list.taken_items).to eql([{"item" => "Brown Ale", "guests"=>[@rico_attendee.id]}])
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity"=> 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2}, {"item" => "Brown Ale", "quantity" => 0}])

				@rico_attendee.rsvp = "Not Going"
				@rico_attendee.dish = []
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(@rico_attendee.rsvp).to eql("Not Going")
				expect(@rico_attendee.dish).to eq([])
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity"=> 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2}, {"item" => "Brown Ale", "quantity" => 1}])
				expect(refreshed_list.taken_items).to eql([])
			end
		end

		describe "Taken items validation" do
			it "should not be valid if you are choosing an item that has been selected" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false}]
				@rico_attendee.save

				@bob_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false}]
				@bob_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(@bob_attendee.dish).to eq([])
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity"=> 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2}, {"item" => "Brown Ale", "quantity" => 0}])
				expect(refreshed_list.taken_items).to eql([{"item" => "Brown Ale", "guests" => [@rico_attendee.id]}])
			end

			it "should not be valid if guest rsvped with duplicate item that is not present in available items (or taken)" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false},{"category"=>"Beer","item"=>"Brown Ale", "quantity" => 1, "is_custom" => false}]
				expect(@rico_attendee).to_not be_valid
			end
		end
		
		describe "Differences in RSVP items" do
			it "should be able to add one more item without a problem" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 1, "is_custom" => false},{"category" => "Beer", "item" => "12-12-12", "quantity" => 1, "is_custom" => true}]
				@rico_attendee.save
				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 1}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 1}])
				expect(refreshed_list.taken_items).to eql([{"guests"=>[@rico_attendee.id], "item"=>"IPA"}])

				@rico_attendee.dish << {"category"=>"Beer", "item" => "Pale Ale", "quantity" => 1, "is_custom" => false}
				@rico_attendee.dish << {"category"=>"Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false}
				@rico_attendee.dish << {"category"=>"Beer", "item" => "Stout", "quantity" => 1, "is_custom" => false}
				@rico_attendee.save
				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 0}, {"item" => "IPA", "quantity" => 1}, {"item" => "Pale Ale", "quantity" => 1},{"item" => "Brown Ale", "quantity" => 0}])
				expect(refreshed_list.taken_items).to eql([{"guests" => [@rico_attendee.id], "item" => "IPA"},{"guests" => [@rico_attendee.id], "item" => "Pale Ale"},{"guests"=>[@rico_attendee.id], "item"=>"Brown Ale"},{"guests"=>[@rico_attendee.id],"item"=>"Stout"}])
			end

			it "should be able to detect removals without a problem" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false},{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false}]
				@rico_attendee.save
				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 0}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 0}])
				expect(refreshed_list.taken_items).to eql([{"guests"=>[@rico_attendee.id], "item"=>"IPA"},{"guests"=> [@rico_attendee.id], "item"=>"Brown Ale"}])

				@rico_attendee.dish.delete_at(1)
				expect(@rico_attendee.dish).to eql([{"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false}])
				@rico_attendee.save
				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 0}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 1}])
				expect(refreshed_list.taken_items).to eql([{"guests" => [@rico_attendee.id], "item" => "IPA"}])
			end
			
			it "should still okay if no changes have been detected" do
				@rico_attendee.dish = [{"category" => "Beer", "item" => "IPA", "quantity" => 2, "is_custom" => false},{"category" => "Beer", "item" => "Brown Ale", "quantity" => 1, "is_custom" => false}]
				@rico_attendee.save
				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 0}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 0 }])
				expect(refreshed_list.taken_items).to eql([{"guests"=>[@rico_attendee.id], "item"=>"IPA"},{"guests"=>[@rico_attendee.id], "item"=>"Brown Ale"}])

				@rico_attendee.num_of_guests = 2
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 0}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 0 }])
				expect(refreshed_list.taken_items).to eql([{"guests" => [@rico_attendee.id], "item"=>"IPA"},{"guests"=>[@rico_attendee.id], "item"=>"Brown Ale"}])
			end

			it "should be able to detect additions and removals at various times" do
				@rico_attendee.dish = [{"category"=>"Beer","item"=>"IPA","quantity"=>1,"is_custom"=>false},{"category"=>"Beer","item"=>"Pale Ale","quantity"=>1,"is_custom"=>false},{"category"=>"Beer","item"=>"12-12-12","is_custom"=>true}]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 1}, {"item" => "Pale Ale", "quantity" => 1},{"item" => "Brown Ale", "quantity" => 1 }])
				expect(refreshed_list.taken_items).to eql([{"guests" => [@rico_attendee.id], "item"=>"IPA"},{"guests" => [@rico_attendee.id],"item"=>"Pale Ale"}])


				@rico_attendee.dish = [{"category"=>"Beer","item"=>"IPA","quantity" => 2, "is_custom"=>false},{"category"=>"Beer","item"=>"Lukcy Basterd","quantity" => 1, "is_custom"=>true},{"category"=>"Beer","item"=>"Stout", "quantity"=>1, "is_custom"=>false}]
				@rico_attendee.save

				refreshed_list = PotluckItem.find(@potluck_items.id)
				expect(refreshed_list.dishes).to eql([{"item" => "Stout", "quantity" => 0}, {"item" => "IPA", "quantity" => 0}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 1 }])
				expect(refreshed_list.taken_items).to eql([{"guests" => [@rico_attendee.id],"item"=>"IPA"},{"guests"=> [@rico_attendee.id], "item"=>"Stout"}])
			end
		end
	end

	describe "Removing Guests" do
		before(:each) do
			User.destroy_all
			Event.destroy_all
			@settings = FactoryGirl.create(:setting)
			@event = @settings.event
		end

		it "should remove the role(s) from the event" do
			@bob = FactoryGirl.create(:bob)
			@attendee = Attendee.create(:event_id => @event.id, :user_id => @bob.id, :rsvp => "Going", :email => @bob.email)
			Role.create(:user_id => @bob.id, :event_id => @event.id, :privilege => Role.GUEST)

			Attendee.destroy(@attendee)
			expect(Role.where("user_id = ? and event_id = ?",@bob.id,@event.id).count).to eql(0)
		end

		it "should reclaim the rsvped items upon delete" do
			@attendee = FactoryGirl.create(:attendee, :event_id => @event.id, :rsvp=>"Going")
			event = @event
			@potluck_list1 = FactoryGirl.create(:potluck_item, :event_id => event.id, :host_quantity => 3, :category => "Beer", :dishes => [{"item" => "IPA", "quantity" => 1},{"item" => "Pale Ale", "quantity" => 1},{"item" => "Stout", "quantity" => 1},{"item" => "Trippels", "quantity" => 1}])
			@potluck_list2 = FactoryGirl.create(:potluck_item, :event_id => event.id, :host_quantity => 2, :category => "Snacks", :dishes => [{"item" => "Doritos","quantity" => 1},{"item"=>"Pretzel","quantity" => 1}])

			@attendee.dish = [{"category" => "Beer","item"=>"IPA","quantity"=>1,"is_custom" => false},{"category"=>"Snacks","item"=>"Pretzel", "quantity"=>1, "is_custom" => false}]
			@attendee.save

			refreshed_list1 = PotluckItem.find(@potluck_list1)
			refreshed_list2 = PotluckItem.find(@potluck_list2)

			expect(refreshed_list1.dishes).to eql([{"item" => "IPA", "quantity" => 0},{"item" => "Pale Ale", "quantity" => 1},{"item" => "Stout", "quantity" => 1},{"item" => "Trippels", "quantity" => 1}])
			expect(refreshed_list1.taken_items).to eql([{"guests" => [@attendee.id], "item" => "IPA"}])
			expect(refreshed_list2.dishes).to eql([{"item" => "Doritos","quantity" => 1},{"item"=>"Pretzel","quantity" => 0}])
			expect(refreshed_list2.taken_items).to eql([{"guests" => [@attendee.id], "item" => "Pretzel"}])

			@attendee.destroy

			refreshed_list1 = PotluckItem.find(@potluck_list1)
			refreshed_list2 = PotluckItem.find(@potluck_list2)

			expect(refreshed_list1.dishes).to eql([{"item" => "IPA", "quantity" => 1},{"item" => "Pale Ale", "quantity" => 1},{"item" => "Stout", "quantity" => 1},{"item" => "Trippels", "quantity" => 1}])
			expect(refreshed_list1.taken_items).to eql([])
			expect(refreshed_list2.dishes).to eql([{"item" => "Doritos","quantity" => 1},{"item"=>"Pretzel","quantity" => 1}])
			expect(refreshed_list2.taken_items).to eql([])
		end
	end
end
