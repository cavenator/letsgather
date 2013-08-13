class Attendee < ActiveRecord::Base
		belongs_to :event
  # attr_accessible :title, :body
		devise :token_authenticatable
		attr_accessible :event_id, :user_id, :invitation_id, :full_name, :email, :rsvp, :num_of_guests, :comment, :dish, :is_host, :invite_sent
		serialize :dish

		before_validation do |attendee|
			attendee.dish = JSON.parse(attendee.dish) unless attendee.dish.blank? || attendee.dish.is_a?(Array)
		end

		validates :event_id, :rsvp, :presence => true
		validates :email, :uniqueness => { :scope => :event_id, :message => "should be unique per event", :allow_blank => true }
		validates :email, :email_format => { :message => 'is not looking good', :allow_blank => true }
		validates :rsvp, :inclusion => { :in => ["Going", "Not Going", "Undecided","No Response"] , :message => "needs to be submitted with 'Going', 'Not Going', 'Undecided'" }
		validates :num_of_guests, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :message => "need to be specified with a number" }
		validate  :verify_host_is_not_guest, :unless => Proc.new {|a| a.event.blank? }
		validate  :verify_correctness_of_dishes, :unless => :is_dish_empty?
		validate  :verify_items_are_available, :unless => Proc.new { |a| a.is_dish_empty? || a.id.blank? }

		after_create do |attendee|
			#Now gotta make sure that manual attendee creation with rsvp works with items
			attendee.dish.each do |item|
				potluck_item = attendee.event.get_potluck_list_per_category(item["category"])
				if potluck_item.taken_items.blank?
					potluck_item.taken_items = []
				end
				unless item["is_custom"] 
					potluck_item.remove_dish_from_list(potluck_item.dishes.find_index(item["item"]), {"id"=>attendee.id, "item"=>item["item"]})
				end
			end
		end

		before_save do |attendee|
			if attendee.id
			#only perform this block once the attendee has actually been created and has an id
				attendee.filter_out_potluck_lists
				if attendee.event.has_notification_settings_on?
					NotificationDelegator.send_notifications_to_host_from(attendee)
				end
			end
		end

		after_destroy do |attendee|
			unless attendee.user_id.blank?
				role = Role.where("user_id = ? and event_id = ?", attendee.user_id, attendee.event_id).first
			end

			Role.destroy(role) unless role.blank?

			attendee.dish.each do |item|
				potluck_item = attendee.event.get_potluck_list_per_category(item["category"])
				unless item["is_custom"]
					potluck_item.make_item_available(item["item"], potluck_item.taken_items.find_index({"id"=>attendee.id, "item" => item["item"]}))
				end
			end
		end

		#accepts an email list in the form of an Array and the event object
		def self.invite(email_list, event, inviter)
			email_hash = {"successful" => [], "unsuccessful" => [], "duplicated" => []}
			email_list.each do |email|
				attendee = Attendee.new(:event_id => event.id, :email => email, :rsvp => "No Response", :invite_sent => true)
				if attendee.valid? 
					attendee.ensure_authentication_token!
					email_hash["successful"] << email
					AttendeeMailer.delay.welcome_guest(attendee, inviter)
				else
					email_hash["unsuccessful"] << email
				end
			end
			AttendeeMailer.delay.send_host_guest_acknowledgement(email_hash, event)
			return email_hash
		end

		def full_name_or_email
			if self.full_name.blank?
				return self.email
			else
				return self.full_name
			end
		end

		def is_dish_empty?
			return self.dish.blank?
		end

		def verify_correctness_of_dishes
			self.dish.each do |item|
				if item["category"].blank? || item["item"].blank?
					errors.add(:dish, " should have both a category and an item declared. You have selected #{item['category']} with item #{item['item']}")
				end
			end
		end

		#previous_state = previous saved persistant representation of attendee
		#this method is invoked prior to saving the attendee but after passing validation
		def difference_between(previous_state)
			differences = {}
				if !self.rsvp.eql?(previous_state.rsvp)
					differences["rsvp"] = self.rsvp
				end

				if !self.comment.eql?(previous_state.comment)
					differences["comment"] = self.comment
				end

				if !self.num_of_guests.eql?(previous_state.num_of_guests)
					differences["num_of_guests"] = self.num_of_guests
				end

				if !self.dish.eql?(previous_state.dish)
					differences["dish"] = self.dish
				end
			return differences
		end

		#previous_state = previous saved persistant representation of attendee
		#this method is invoked prior to saving the attendee but after passing validation
		def has_differences_between?(previous_state)
			return !self.difference_between(previous_state).blank? && !self.user_id.blank?
		end

		def verify_host_is_not_guest
			errors.add(:email, " should not be the same as host. Please provide an email or none at all.") if self.event.user.email.eql?(self.email)
		end

		#TODO:  Refactor this ugly-as-sin method!!
		def filter_out_potluck_lists
				if self.rsvp == "Going"
					unless self.dish.blank? #execute the block if attendee has items. Mark available items as taken
						#find the delta (previous state versus what we have now) and run the loop
						#should create a comprehensive map so that the deltas could be tracked. a map with each of the categories
						previous_state = Attendee.find(self.id)
						previous_list = previous_state.dish
						self.dish.each do |item|
							potluck_item = self.event.get_potluck_list_per_category(item["category"])
							if potluck_item.taken_items.blank?
								potluck_item.taken_items = []
							end
							unless item["is_custom"] 
								if previous_list.blank? || previous_list.find_index(item).nil?
									potluck_item.remove_dish_from_list(potluck_item.dishes.find_index(item["item"]), {"id"=>self.id, "item"=>item["item"]})
								elsif previous_list.find_index(item)
									previous_list.delete_at(previous_list.find_index(item))
								end
							end
						end
						unless previous_list.blank?
							previous_list.each do |remove_item|
								unless remove_item["is_custom"]
									potluck_item = self.event.get_potluck_list_per_category(remove_item["category"])
									potluck_item.make_item_available(remove_item["item"], potluck_item.taken_items.find_index({"id"=> self.id, "item" => remove_item["item"]}))
								end
							end
						end
					else #updated attendee dish selection is empty while previous state has items defined. Make items available for selection again
						if self.id
							previous_state = Attendee.find(self.id)
							previous_state.dish.each do |dish|
								unless dish["is_custom"]
									potluck_item = self.event.get_potluck_list_per_category(dish["category"])
									potluck_item.make_item_available(dish["item"], potluck_item.taken_items.find_index({"id"=> self.id, "item"=>dish["item"]}))
								end
							end
						end
					end
				else
				#Attendee is not going. Make sure to return taken items to available column again
					previous_state = Attendee.find(self.id)
					previous_state.dish.each do |item|
						potluck_item = self.event.get_potluck_list_per_category(item["category"])
						unless item["is_custom"]
							potluck_item.make_item_available(item["item"], potluck_item.taken_items.find_index({"id"=> self.id, "item"=>item["item"]}))
						end
					end
				end
		end

		def verify_items_are_available
			complete_list = self.dish
			unique_list = self.dish.uniq
			unique_list.each do |uniq_item|
				unless uniq_item["is_custom"]
					potluck_item = self.event.get_potluck_list_per_category(uniq_item["category"])
					items_available = potluck_item.dishes.find_all{|i| i == uniq_item["item"] }.count
					attendee_item_count = complete_list.find_all{|i| i.eql?(uniq_item)}.count
					taken_item_count = potluck_item.taken_items.find_all {|i| i.eql?({"id" => self.id, "item" => uniq_item["item"]})}.count
					unless (items_available + taken_item_count) >= attendee_item_count
							errors.add(:dish, 'Attempted to use one too many of the same item to rsvp with')
					end
				end
			end
		end

		def self.find_attendee_for(user, event)
			return event.attendees.where('user_id = ?', user.id).first
		end

		def self.find_rsvp_for(user, event)
			attendee = self.find_attendee_for(user,event)
			if attendee.rsvp.eql?("No Response")
				return "You have not yet responded"
			elsif attendee.rsvp.eql?("Undecided")
				return "You are currently a Maybe"
			else
				return "You are currently #{attendee.rsvp}"
			end
		end

		def can_cohost?
			unless self.email.blank?
				if self.user_id.blank?
					return self.is_host
				else
					role = Role.where('user_id =? and event_id =?', self.user_id, self.event_id).first
					return role.privilege.eql?(Role.HOST)
				end
			end
			return false
		end

		def change_roles
			if self.user_id.blank?
				if self.is_host
					self.is_host = false
				else
					self.is_host = true
				end
				if self.save
					return true
				else 
					return false
				end
			else
				role = Role.get_role_for(self.user_id, self.event_id)
				if role.privilege.eql?(Role.GUEST)
					role.privilege = Role.HOST
				else
					role.privilege = Role.GUEST
				end
				if role.save
					return true
				else
					return false
				end
			end
		end

		def has_role_for_event?(event)
			unless self.user_id.blank?
				role = Role.where('user_id = ? and event_id = ?',self.user_id, event.id)
				return !role.blank?
			end
			return false
		end
end
