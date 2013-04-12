require 'spec_helper'

describe Group do
	describe "minimum group requirements" do
		before(:all) do
			User.destroy_all
			@user = FactoryGirl.create(:user)
		end

		it "should always have a name and at least one email" do
			@group = Group.new(:user_id => @user.id)
			expect(@group).to_not be_valid
		end

		it "should have a unique name per group per user" do
			@group = Group.create(:user_id => @user.id, :name => "Sample group", :email_distribution_list => "testperson@gmail.com")
			expect(@user.groups.count) == 1
			
			@group2 = Group.create(:user_id => @user.id, :name => "Sample group", :email_distribution_list => "testperson2@gmail.com")
			expect(@group2).to_not be_valid
		end

		it "should verify that the email distribution list is an actual array" do
			@group = Group.new(:user_id => @user.id, :name => "My first group")
			expect(@group).to_not be_valid
			@group.email_distribution_list = "hellothere@gmail.com"
			expect(@group.email_distribution_list).to be_an_instance_of String
			expect(@group).to be_valid
			expect(@group.email_distribution_list).to be_an_instance_of Array
		end

		it "should verify that email distribution list has unique emails" do
			@group = Group.new(:user_id => @user.id, :name => "My first group")
			@group.email_distribution_list = "example@gmail.com","example2", "example@gmail.com"
			expect(@group).to_not be_valid
			@group.email_distribution_list = "example@gmail.com","example2@hotmail.com"
			expect(@group).to be_valid
		end
	end
end
