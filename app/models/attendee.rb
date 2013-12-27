class Attendee < ActiveRecord::Base
		belongs_to :event
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
		validate  :verify_correctness_of_dishes, :unless => Proc.new { |a| a.is_dish_empty? || a.id.blank? }
		validate  :verify_items_are_available, :unless => Proc.new { |a| a.is_dish_empty? || a.id.blank? || a.has_obsolete_key? }

		#deleted after_create callback since no longer able to add potlick_items to new attendee. New constraints
			#TODO:  Remove the JS functions from the attendees/new.html.erb

		before_save do |attendee|
			unless attendee.id.blank?
			#only perform this block once the attendee has actually been created and has an id
			# obsolete -> attendee.sort_out_taken_items
				unless self.has_obsolete_key?
					Attendee.compareWithPreviousStateAndUpdateDeltas(attendee)
					if attendee.event.has_notification_settings_on?
						NotificationDelegator.send_notifications_to_host_from(attendee)
					end
				end
			end
		end

		after_destroy do |attendee|
			unless attendee.user_id.blank?
				role = Role.where("user_id = ? and event_id = ?", attendee.user_id, attendee.event_id).first
			end

			Role.destroy(role) unless role.blank?

			PotluckItem.make_items_available(attendee, attendee.event)
		#	attendee.dish.each do |item|
		#		potluck_item = attendee.event.get_potluck_list_per_category(item["category"])
		#		unless item["is_custom"]
		#			potluck_item.make_item_available(item["item"], attendee.id)
		#		end
		#	end
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

		def has_obsolete_key?
			self.dish.reduce(0) do |sum, val|
				if val.has_key?("guest")
					sum + 1
				else
					sum
				end
			end
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

		def unapply_delta(delta)
			item_index = self.dish.index{ |x| x["category"].eql?(delta["category"]) && x["item"].eql?(delta["item"]) }
			item = self.dish.at(item_index)
			quantity_difference = item["quantity"] - delta["quantity"]
			if quantity_difference > 0
				item["quantity"] = item["quantity"] - delta["quantity"]
			else
				self.dish.delete_at(item_index)
			end
		end

#		def sort_out_taken_items
#			previous_state = Attendee.find(self.id)
#			previous_list = previous_state.dish
#			event = self.event
#
#			if self.rsvp == "Going"
#					#execute the block if attendee has items. Mark available items as taken
#					#find the delta (previous state versus what we have now) and run the loop 
#					#returns the delta as a comprehensive map 
#				unless self.dish.blank?
#					leftover_taken_items = PotluckItem.return_taken_list_delta(self, event, previous_list)
#					unless leftover_taken_items.blank?
#						PotluckItem.make_items_available(previous_state, event, leftover_taken_items)
#					end
#				else #updated attendee dish selection is empty while previous state has items defined. Make items available for selection again
#					unless self.id.blank?
#						PotluckItem.make_items_available(previous_state, event, nil)
#					end
#				end
#			else
#			#Attendee is not going. Make sure to return taken items to available column again
#				PotluckItem.make_items_available(previous_state, event, nil)
#			end
#		end

		def self.compareWithPreviousStateAndUpdateDeltas(attendee)
			previous_state = Attendee.find(attendee.id)
			previous_list = previous_state.dish
			event = attendee.event

			if attendee.rsvp == "Going"
				#get deltas per list
				deltas = attendee.get_deltas_from_list(previous_list)
				logger.debug "deltas = #{deltas}"
				#unless no deltas exist, merge and update with the potluck list
				unless deltas.blank?
					PotluckItem.mergeDeltasAndUpdateIfNecessary(deltas, attendee)
				end
			else
			#Attendee is not going. Make sure to return taken items to available column again
				#PotluckItem.make_items_available(previous_state, event, nil)
				PotluckItem.make_items_available(previous_state, event)
				attendee.dish = [] 
			end
		end

		def get_deltas_from_list(previous_list)
			delta_array = []
			previous_list_cache = []
			self.dish.each do |dish|
				unless dish["is_custom"]
					previous_dish = previous_list.find{ |x| x["category"].eql?(dish["category"]) && x["item"].eql?(dish["item"])}
					if previous_dish.blank?
						delta_array << { "category" => dish["category"], "item" => dish["item"], "is_custom" => dish["is_custom"], "quantity" => dish["quantity"] }
					else
						previous_list_cache << previous_dish
						delta_array << {"category" => dish["category"], "item" => dish["item"], "is_custom" => dish["is_custom"], "quantity" => dish["quantity"] - previous_dish["quantity"] }
					end
				end
			end
			outstanding_items = previous_list.reject{|x| previous_list_cache.include?(x)}
			outstanding_items.each do |outstanding_item|
				unless outstanding_item["is_custom"]
					copy_of_item = outstanding_item
					copy_of_item["quantity"] = -1 * copy_of_item["quantity"]
					copy_of_item["removed"] = true
					delta_array << copy_of_item
				end
			end
			delta_array
		end

		def verify_items_are_available
			complete_list = self.dish
			unique_list = self.dish.uniq
			unique_list.each do |uniq_item|
				unless uniq_item["is_custom"]
					potluck_item = self.event.get_potluck_list_per_category(uniq_item["category"])
					items_available = potluck_item.dishes.find_all{|i| i["item"] == uniq_item["item"] }.count
					attendee_item_count = complete_list.find_all{|i| i.eql?(uniq_item)}.count
					taken_item_count = potluck_item.taken_items.find_all {|i| i["item"].eql?(uniq_item["item"]) && i["guests"].include?(self.id)}.count
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

		def change_roles_and_notify(host)
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
					NotificationMailer.delay.notify_guest_of_new_privileges(self, role.privilege, host)
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
