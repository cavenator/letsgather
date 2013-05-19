class Role < ActiveRecord::Base
	belongs_to :user
  # attr_accessible :title, :body
	attr_accessible :user_id, :event_id, :privilege
	validates :user_id, :uniqueness => { :scope => :event_id }

	def self.GUEST
		"guest"
	end

	def self.HOST
		"host"
	end

	def self.get_role_for(user_id, event_id)
		return Role.where('user_id = ? and event_id = ?', user_id, event_id).first
	end

end
