require 'spec_helper'

describe "potluck_items/edit" do
  before(:each) do
    @potluck_item = assign(:potluck_item, stub_model(PotluckItem))
  end

  it "renders the edit potluck_item form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => potluck_items_path(@potluck_item), :method => "post" do
    end
  end
end
