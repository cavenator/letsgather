require 'spec_helper'

describe "potluck_items/index" do
  before(:each) do
    assign(:potluck_items, [
      stub_model(PotluckItem),
      stub_model(PotluckItem)
    ])
  end

  it "renders a list of potluck_items" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
