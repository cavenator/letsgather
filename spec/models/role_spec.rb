require 'spec_helper'

describe Role do
	describe "Roles basic capabilities" do
		it "should be able to detect enum types" do
			expect(Role.GUEST).to eql("guest")
			expect(Role.HOST).to eql("host")
		end
	end
end
