require 'spec_helper'

describe "potluck_items/show" do
  before(:each) do
    @potluck_item = assign(:potluck_item, stub_model(PotluckItem))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
