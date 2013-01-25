FactoryGirl.define do

	factory :user do
		first_name 'Alice'
		last_name 'Cooper'
		email { "#{first_name}.#{last_name}@gmail.com" }
		password 'test123'
	end

		factory :bob, class: User do
			first_name 'Bob'
			last_name 'Barker'
			email { "#{first_name}.#{last_name}@gmail.com" }

			password 'test456'
		end

		factory :rico, class: User do
			first_name 'Rico'
			last_name 'Suave'
			email { "#{first_name}.#{last_name}@gmail.com" }
			password 'test789'
		end

end
