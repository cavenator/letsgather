require 'spec_helper'

describe "potluck_items/new" do
  before(:each) do
    assign(:potluck_item, stub_model(PotluckItem).as_new_record)
  end

  it "renders new potluck_item form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => potluck_items_path, :method => "post" do
    end
  end
end
