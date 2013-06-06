class Settings < ActiveRecord::Base
	belongs_to :event
		attr_accessible :event_id, :notify_on_guest_accept, :notify_on_guest_decline, :notify_on_guest_response, :days_rsvp_reminders, :days_event_reminders
		validates :event_id, :presence => true
		validates :days_rsvp_reminders, :days_event_reminders, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :message => "need to be specified with a number ( 0 and greater)" }

end
