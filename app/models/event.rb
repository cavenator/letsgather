class Event < ActiveRecord::Base
		has_many :attendees 
		has_many :potluck_items
		has_many :suggestions, :dependent => :destroy
		has_one :settings, :dependent => :destroy
		belongs_to :user

		validates :name,:user_id, :start_date, :end_date, :rsvp_date, :contact_number, :presence => true
		validates :description, :length => { :maximum => 1500, :too_long => "%{count} characters is the maximum allowed" }
		validates :contact_number, :format => { :with => /\([0-9]{3}\)\s[0-9]{3}-[0-9]{4}$/, :message => "has to be (XXX) XXX-XXXX" }
		validate :start_date_must_be_in_right_format
		validate :end_date_must_be_in_right_format
		validate :rsvp_date_must_be_in_right_format
		validate :start_date_must_be_in_the_future
		validate :end_date_must_be_in_the_future
		validate :rsvp_date_should_be_less_than_start_date
		validate :start_date_should_be_less_than_end_date

   attr_accessible :name, :start_date, :end_date, :user_id, :rsvp_date, :supplemental_info, :contact_number, :address1, :address2, :city, :state, :zip_code, :description, :theme, :settings_attributes

	accepts_nested_attributes_for :settings

	before_destroy do |event|
		unless event.end_date == nil || Time.now > event.end_date
			email_list = event.get_unique_guest_email_list
			host = event.user
			AttendeeMailer.delay.send_event_cancellation(email_list, event.name, host.full_name, host.email)
		end
		event.attendees.destroy_all
		event.potluck_items.destroy_all
	end

	def start_date_must_be_in_the_future
			unless self.start_date.blank?
				errors.add(:start_date,"cannot start in the past") if self.start_date < Date.today
			end
	end

	def end_date_must_be_in_the_future
			unless self.end_date.blank?
				errors.add(:end_date,"end date must be in the future") if self.end_date < Date.today
			end
	end

	def rsvp_countdown
		days = ((self.rsvp_date.in_time_zone("Pacific Time (US & Canada)") - Time.now.in_time_zone("Pacific Time (US & Canada)"))/86400).ceil
		unless days == 1
			statement = "You have "+days.to_s+" days left to RSVP"
		else
			statement = "You have 1 day left to RSVP"
		end
		return statement
	end

	def start_date_must_be_in_right_format
		unless self.start_date.blank?
			errors.add(:start_date, 'must be a valid datetime format: MM/dd/yyyy hh:mm:ss PM (or AM)') if ((DateTime.parse(self.start_date.to_s) rescue ArgumentError) == ArgumentError)
		end
	end

	def end_date_must_be_in_right_format
		unless self.end_date.blank?
			errors.add(:end_date, 'must be a valid datetime format: MM/dd/yyyy hh:mm:ss PM (or AM)') if ((DateTime.parse(self.end_date.to_s) rescue ArgumentError) == ArgumentError)
		end
	end

	def rsvp_date_must_be_in_right_format
		unless self.rsvp_date.blank?
			errors.add(:rsvp_date, 'must be a valid datetime format: MM/dd/yyyy hh:mm:ss PM (or AM)') if ((DateTime.parse(self.rsvp_date.to_s) rescue ArgumentError) == ArgumentError)
		end
	end

	def rsvp_date_should_be_less_than_start_date
		unless self.rsvp_date.blank? || self.start_date.blank?
			errors.add(:rsvp_date, "rsvp date must be before the event start date") if self.rsvp_date > self.start_date
		end
	end

	def start_date_should_be_less_than_end_date
		unless self.end_date.blank? || self.start_date.blank?
			errors.add(:start_date, "start date must be before the event's end date") if self.start_date > self.end_date
		end
	end

	def display_start_time
		return self.start_date.in_time_zone("Pacific Time (US & Canada)").strftime("%b %d,%Y %I:%M %p")
	end

	def display_end_time
		return self.end_date.in_time_zone("Pacific Time (US & Canada)").strftime("%b %d,%Y %I:%M %p")
	end

	def display_rsvp_time
		return self.rsvp_date.in_time_zone("Pacific Time (US & Canada)").strftime("%b %d,%Y %I:%M %p")
	end

	def attending_guest_count
		attending_guests = self.attendees.where("rsvp = 'Going'")
		guest_count = attending_guests.count
		attending_guests.each do |attendee|
			guest_count += attendee.num_of_guests
		end
		return guest_count
	end

	def has_notification_settings_on?
		return self.settings.notify_on_guest_accept || self.settings.notify_on_guest_decline || self.settings.notify_on_guest_response
	end

	def find_attendee_dish_count(category)
		category_count = 0
		self.attendees.where("rsvp = 'Going'").each do |attendee|
			category_count += attendee.dish.find_all { |item| item["category"].eql?(category) }.count
		end
		return category_count
	end

	def location
		return true if !self.address1.blank? && !self.location2.blank?
	end

	def location1
		returnString = String.new
		returnString += self.address1 if self.address1
		returnString += (", "+self.address2) if self.address2 && self.address1
		return returnString
	end

	def location2
		returnString = String.new
		returnString += self.city if self.city
		returnString += ", "+self.state if self.state
		returnString += "  "+self.zip_code if self.zip_code && self.state
		return returnString
	end

	def get_potluck_items_for_guests
		return self.potluck_items.map{|i| {"category" => i.category, "dishes" => i.dishes} }
	end

	def get_host_quantity_for_each_category
		return Hash[self.potluck_items.map{ |i| [i.category, i.host_quantity] }]
	end

	def get_remaining_items_for_guests
		category_hash = self.get_host_quantity_for_each_category
		remaining_count_hash = Hash.new
		category_hash.each do |key, value|
			guest_category_count = self.find_attendee_dish_count(key)
			unless guest_category_count >= value
				remaining_count_hash[key] = value - guest_category_count
			end
		end
		remaining_count_hash
	end

	def get_available_items_for_event
		items = []
		self.potluck_items.each do |potluck_item|
			items << {"category" => potluck_item.category, "available_items" => potluck_item.dishes }
		end
		return items
	end

	def get_items_guests_are_bringing
		guests = self.attendees.where("rsvp = 'Going'")
		items = []
		self.potluck_items.each do |potluck_item|
			items << {"category" => potluck_item.category, "taken_items" => [] }
		end

		guests.each do |guest|
			unless guest.dish.empty?
				guest.dish.each do |item|
					items.each do |stored_items|
						if item["category"].eql?(stored_items["category"])
							taken_item_index = stored_items["taken_items"].index{ |x| x["item"].eql?(item["item"]) }
							if taken_item_index.blank?
								stored_items["taken_items"] << {"item" => item["item"], "count" => 1}
							else
								stored_items["taken_items"][taken_item_index]["count"] = stored_items["taken_items"][taken_item_index]["count"] + 1
							end
						end
					end
				end
			end
		end
		return items
	end

	def self.events_for_rsvp_reminders
		events = Event.joins(:settings).where('rsvp_date >= ? and settings.days_rsvp_reminders <> 0', Time.now)
		today = Time.now.utc.to_date
		rsvp_days = events.map{ |event| today + event.settings.days_rsvp_reminders }.uniq
		return events.select {|event| rsvp_days.include?(event.rsvp_date.to_date) }
	end

	def send_rsvp_reminders_for_all_attendees
		attendees_with_email = self.attendees.where("email is not null")
		attendees_with_email.each do |attendee|
			unless !attendee.authentication_token.blank?
				attendee.ensure_authentication_token!
			end
			ReminderMailer.delay.send_rsvp_emails(attendee)
		end
	end

	def get_unique_guest_email_list
		self.attendees.map(&:email).compact.reject{|email| email.empty? }
	end

	def send_event_reminders_for_attending_guests
		guests = self.attendees.where("rsvp = 'Going' and email is not null")
		guests.each do |guest|
			unless !guest.authentication_token.blank?
				guest.ensure_authentication_token!
			end
			ReminderMailer.delay.send_event_reminders(guest)
		end
	end

	def has_disabled_suggestions
		return self.settings.disable_suggestions
	end

	def self.events_for_event_reminders
		events = Event.joins(:settings).where('start_date >= ? and settings.days_event_reminders <> 0', Time.now)
		today = Time.now.utc.to_date
		event_days = events.map{ |event| today + event.settings.days_event_reminders }.uniq
		return events.select {|event| event_days.include?(event.start_date.to_date) }
	end

	def get_potluck_list_per_category(category)
		self.potluck_items.find_by_category(category)
	end

	def get_potluck_inventory_for_categories(category_array)
		item_hash_array = []
		self.potluck_items.where("category in (?)", category_array).each do |potluck_item|
			item_hash_array << {"category" => potluck_item.category, "available_items" => potluck_item.dishes, "taken_items" => potluck_item.taken_items}
		end
		return item_hash_array
	end

	def get_hosts
		user_ids = Role.where('event_id = ? and privilege = ?', self.id, Role.HOST).map{|role| role.user_id }
		hosts = User.find(user_ids)
		hosts << self.user
		return hosts.uniq
	end
end
