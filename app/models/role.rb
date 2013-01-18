class Role < ActiveRecord::Base
	belongs_to :user
  # attr_accessible :title, :body
	attr_accessible :user_id, :event_id, :privilege
end
