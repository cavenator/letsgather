desc "Heroku scheduled job for rsvp reminders"
	task :rsvp_reminders => :environment do
		puts "Currently executing RSVP reminders"
		events = Event.get_events_for_rsvp_reminders
		puts "Got events. Total count = #{events.count}"
		puts "Time to loop them"
		events.each do |event|
			puts "event name = #{event.name}, rsvp = #{event.rsvp_date}, start date = #{event.start_date}"
			event.send_rsvp_reminders_for_all_attendees
			puts "done sending emails to attendees"
		end
	end

desc "Heroku scheduled job for event reminders to attending guests"
	task :send_event_reminders => :environment do
		puts "Currently finding events"
		events = Event.get_events_for_event_reminders
		puts "Got events. Total count = #{events.count}"
		puts "time to loop"
		events.each do |event|
			puts "looping event name = #{event.name}"
			event.send_event_reminders_for_attending_guests
			puts "done sending emails to attendees"
		end
	end
