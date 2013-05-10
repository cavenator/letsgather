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

end
