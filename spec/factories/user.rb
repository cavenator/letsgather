FactoryGirl.define do
	factory :user do
		first_name 'Alice'
		last_name 'Cooper'
		email {"#{first_name}.#{last_name}@gmail.com"}
		password 'test123'
	end
end
