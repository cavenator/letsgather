class User < ActiveRecord::Base
	has_many :events, :dependent => :destroy
	has_many :roles, :dependent => :destroy
	has_many :groups, :dependent => :destroy

	before_destroy do |user|
		attendee_reference = Attendee.where("user_id = ? or email = ?", user.id, user.email)
		attendee_reference.destroy_all
	end

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :future_options
	serialize :future_options
  # attr_accessible :title, :body

	validates :first_name,:last_name, :presence => true

	def full_name
		return self.first_name+" "+self.last_name
	end

	def is_host_for?(event)
		return self.id == event.user.id || Role.where('user_id = ? and event_id = ? and privilege = ?',self.id, event.id, Role.HOST).count == 1
	end

	def belongs_to_event?(event)
		return self.roles.where("event_id = ?", event.id).count > 0
	end

	def transfer_settings_for_event(event)
		settings = Settings.find_by_event_id(event.id)
		self.future_options.each do |key, value|
			case key when "notify_on_guest_accept"
				settings.notify_on_guest_accept = value
			when "notify_on_guest_decline"
				settings.notify_on_guest_decline = value
			when "notify_on_guest_response"
				settings.notify_on_guest_response = value
			when "days_rsvp_reminders"
				settings.days_rsvp_reminders = value
			when "days_event_reminders"
				settings.days_event_reminders = value
			else
			end
		end
		settings.save
	end
end
