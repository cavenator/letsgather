FactoryGirl.define do
	factory :user do
		first_name 'Alice'
		last_name 'Cooper'
		email {"#{first_name}.#{last_name}@gmail.com"}
		password 'test123'
			
		factory :bob do
			first_name 'Bob'
			last_name 'Barker'
			password 'test456'
		end
	end
end
