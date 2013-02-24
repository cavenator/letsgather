# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :potluck_item do
		category "Beer"
		dishes ["Stout", "IPA", "Pale Ale","Brown Ale"]
		host_quantity 2
		event
  end
end
