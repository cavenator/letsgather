require 'spec_helper'

describe User do
	describe "basic user profile" do
		it "should have at a bare minimum an email and password" do
			user = FactoryGirl.create(:user)
			expect(User.all.count).to eql(1)
		end

		it "should never have a blank email when modifying the account" do
			user = FactoryGirl.build(:user, :email => nil)
			expect(user).to_not be_valid
			user.save
			user.should have(1).error_on(:email)
		end
	end
end
