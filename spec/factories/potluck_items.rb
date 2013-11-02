# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :potluck_item do
		category "Beer"
		dishes [{"item" => "Stout", "quantity" => 1}, {"item" => "IPA", "quantity" => 2}, {"item" => "Pale Ale", "quantity" => 2},{"item" => "Brown Ale", "quantity" => 1}]
		host_quantity 2
		event
  end
end
