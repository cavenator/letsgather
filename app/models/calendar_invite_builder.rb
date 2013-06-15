require 'ri_cal'

class CalendarInviteBuilder

	def self.createBaseCalendar
		return RiCal.Calendar do timezone do tzid "America/Los_Angeles" end end
	end

	def self.createCalendarInviteFor(eventObject, guest_email)
		calendar = self.createBaseCalendar
		event_subcomponent = RiCal::Component::Event.new
		event_subcomponent.organizer = eventObject.user.email
		event_subcomponent.summary = eventObject.name
		if eventObject.description.blank?
			event_subcomponent.description = "TBD"
		else
			event_subcomponent.description = eventObject.description
		end

		if eventObject.location
			event_subcomponent.location = eventObject.location1 + ","+eventObject.location2
		else
			event_subcomponent.location = "TBD"
		end
		event_subcomponent.dtstart = eventObject.start_date.in_time_zone("Pacific Time (US & Canada)")
		event_subcomponent.dtend = eventObject.end_date.in_time_zone("Pacific Time (US & Canada)")
		event_subcomponent.add_attendee(guest_email)
		calendar.add_subcomponent(event_subcomponent)
		return calendar

	end

	def self.createCalendarInvitesFor(eventObject, guest_emails)
		calendar = self.createBaseCalendar
		event_subcomponent = RiCal::Component::Event.new
		event_subcomponent.organizer = eventObject.user.email
		event_subcomponent.summary = eventObject.name
		if eventObject.description.blank?
			event_subcomponent.description = "TBD"
		else
			event_subcomponent.description = eventObject.description
		end

		if eventObject.location
			event_subcomponent.location = eventObject.location1 + ","+eventObject.location2
		else
			event_subcomponent.location = "TBD"
		end
		event_subcomponent.dtstart = eventObject.start_date.in_time_zone("Pacific Time (US & Canada)")
		event_subcomponent.dtend = eventObject.end_date.in_time_zone("Pacific Time (US & Canada)")
		event_subcomponent.add_attendees(guest_emails)
		calendar.add_subcomponent(event_subcomponent)
		return calendar

	end
end
