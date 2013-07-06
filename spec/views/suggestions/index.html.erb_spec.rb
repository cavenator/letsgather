require 'spec_helper'

describe "suggestions/index" do
  before(:each) do
    assign(:suggestions, [
      stub_model(Suggestion),
      stub_model(Suggestion)
    ])
  end

  it "renders a list of suggestions" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
