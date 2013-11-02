# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :setting, :class => 'Settings' do
		event
		notify_on_guest_accept false
		notify_on_guest_decline false
		notify_on_guest_response false
		days_rsvp_reminders 0
		days_event_reminders 0
		disable_suggestions true
  end
end
