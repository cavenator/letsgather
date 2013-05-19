require 'spec_helper'

describe Role do
	describe "Roles basic capabilities" do
		it "should be able to detect enum types" do
			expect(Role.GUEST).to eql("guest")
			expect(Role.HOST).to eql("host")
		end
	end

	describe "Roles limitations" do
		before(:all) do
			User.destroy_all
			Event.destroy_all
			@user = FactoryGirl.create(:user)
			@event2 = FactoryGirl.create(:event_secondary)
			@rico = @event2.user
			@event3 = FactoryGirl.create(:event_secondary, :name => "Event 3", :user_id => @rico.id)
		end

		it "should only be one per event" do
			role1 = Role.new(:user_id => @user.id, :event_id => @event2.id, :privilege => Role.GUEST)
			expect(role1).to be_valid
			role1.save

			role2 = Role.new(:user_id => @user.id, :event_id => @event2.id, :privilege => Role.HOST)
			expect(role2).to_not be_valid
			role3 = Role.new(:user_id => @user.id, :event_id => @event3.id, :privilege => Role.GUEST)
			expect(role3).to be_valid
			role3.save
			expect(@user.roles.count).to eql(2)
		end
	end
end
