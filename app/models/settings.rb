class Settings < ActiveRecord::Base
	belongs_to :event

		attr_accessible :notify_on_guest_accept, :notify_on_guest_decline, :notify_on_guest_response, :days_rsvp_reminders, :days_event_reminders, :disable_suggestions
		validates :days_rsvp_reminders, :days_event_reminders, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :message => "need to be specified with a number ( 0 and greater)" }

		def self.merge(update_attrs)
			original = self.DEFAULT_SETTINGS
			original.merge(update_attrs)
		end

		def self.DEFAULT_SETTINGS
			return { "notify_on_guest_accept" => false, "notify_on_guest_decline" => false, "notify_on_guest_response" => false , "days_rsvp_reminders" => 0, "days_event_reminders" => 0, "disable_suggestions" => false }
		end

		def self.AdditionalHashInfoForUser
			return { "id" => 0 }
		end

		def self.determineFutureSettings(user)
			unless !user.future_options.blank?
				event_zero = self.AdditionalHashInfoForUser
				return self.DEFAULT_SETTINGS.merge(event_zero)
			end
			return user.future_options
		end
end
