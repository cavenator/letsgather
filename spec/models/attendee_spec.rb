require 'spec_helper'

describe Attendee do

	describe "attendee minimal requirements" do
		it "should have an email, event_id, and rsvp at a minimum" do
			event = FactoryGirl.create(:event)
			attendee = Attendee.new
			expect(attendee).to_not be_valid
			attendee.email = "person@gmail.com"
			attendee.event_id = event.id
			expect(attendee).to_not be_valid
		end
	end

	describe "sending invites to guests" do

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

		it "should deliver an email upon successful email validation" do

		end
	end

end
