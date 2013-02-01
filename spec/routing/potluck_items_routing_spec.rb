require "spec_helper"

describe PotluckItemsController do
  describe "routing" do

    it "routes to #index" do
      get("/potluck_items").should route_to("potluck_items#index")
    end

    it "routes to #new" do
      get("/potluck_items/new").should route_to("potluck_items#new")
    end

    it "routes to #show" do
      get("/potluck_items/1").should route_to("potluck_items#show", :id => "1")
    end

    it "routes to #edit" do
      get("/potluck_items/1/edit").should route_to("potluck_items#edit", :id => "1")
    end

    it "routes to #create" do
      post("/potluck_items").should route_to("potluck_items#create")
    end

    it "routes to #update" do
      put("/potluck_items/1").should route_to("potluck_items#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/potluck_items/1").should route_to("potluck_items#destroy", :id => "1")
    end

  end
end
