# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :host do
		privilege 'host'
  	user
  end
end
