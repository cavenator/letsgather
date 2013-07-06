require 'spec_helper'

describe "suggestions/show" do
  before(:each) do
    @suggestion = assign(:suggestion, stub_model(Suggestion))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
