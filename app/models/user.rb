class User < ActiveRecord::Base
	has_many :events, :dependent => :destroy
	has_many :roles, :dependent => :destroy

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name
  # attr_accessible :title, :body

	validates :first_name,:last_name, :presence => true

	def full_name
		return self.first_name+" "+self.last_name
	end

	def find_role_for(event)
		role = self.roles.where("event_id = ?", event.id).first
		if role
			return role.privilege
		else
			return "Unauthorized"
		end
	end

	def is_host_for?(event)
		return self.find_role_for(event) == "host"
	end

	def belongs_to_event?(event)
		return self.roles.where("event_id = ?", event.id).count > 0
	end
end
