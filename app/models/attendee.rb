class Attendee < ActiveRecord::Base
		belongs_to :event
  # attr_accessible :title, :body
		attr_accessible :event_id, :user_id, :invitation_id, :full_name, :email, :rsvp, :num_of_guests, :comment, :dish
		serialize :dish

		before_validation do |attendee|
			attendee.dish = JSON.parse(attendee.dish) unless attendee.dish.blank? || attendee.dish.is_a?(Array)
		end

		validates :event_id, :rsvp, :presence => true
		validates :email, :uniqueness => { :scope => :event_id, :message => "should be unique per event", :allow_blank => true }
		validates :email, :format => { :with => /^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i, :message => "needs to be a valid email format", :allow_blank => true }
		validates :rsvp, :inclusion => { :in => ["Going", "Not Going", "Undecided"] , :message => "needs to be submitted with 'Going', 'Not Going', 'Undecided'" }
		validates :num_of_guests, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0, :message => "need to be specified with a number" }
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
				if attendee.rsvp == "Going"
					unless attendee.dish.blank? #execute the block if attendee has items. Mark available items as taken
						#find the delta (previous state versus what we have now) and run the loop
						#should create a comprehensive map so that the deltas could be tracked. a map with each of the categories
						previous_attendee_state = Attendee.find(attendee.id)
						previous_attendee_list = previous_attendee_state.dish
						attendee.dish.each do |item|
							potluck_item = attendee.event.get_potluck_list_per_category(item["category"])
							if potluck_item.taken_items.blank?
								potluck_item.taken_items = []
							end
							unless item["is_custom"] 
								if previous_attendee_list.blank? || previous_attendee_list.find_index(item).nil?
									potluck_item.remove_dish_from_list(potluck_item.dishes.find_index(item["item"]), {"id"=>attendee.id, "item"=>item["item"]})
								elsif previous_attendee_list.find_index(item)
									previous_attendee_list.delete_at(previous_attendee_list.find_index(item))
								end
							end
						end
						unless previous_attendee_list.blank?
							previous_attendee_list.each do |remove_item|
								unless remove_item["is_custom"]
									potluck_item = attendee.event.get_potluck_list_per_category(remove_item["category"])
									potluck_item.make_item_available(remove_item["item"], potluck_item.taken_items.find_index({"id"=> attendee.id, "item" => remove_item["item"]}))
								end
							end
						end
					else #updated attendee dish selection is empty while previous state has items defined. Make items available for selection again
						if attendee.id
							previous_attendee_state = Attendee.find(attendee.id)
							previous_attendee_state.dish.each do |dish|
								unless dish["is_custom"]
									potluck_item = attendee.event.get_potluck_list_per_category(dish["category"])
									potluck_item.make_item_available(dish["item"], potluck_item.taken_items.find_index({"id"=>attendee.id, "item"=>dish["item"]}))
								end
							end
						end
					end
				else
				#Attendee is not going. Make sure to return taken items to available column again
					previous_attendee_state = Attendee.find(attendee.id)
					previous_attendee_state.dish.each do |item|
						potluck_item = attendee.event.get_potluck_list_per_category(item["category"])
						unless item["is_custom"]
							potluck_item.make_item_available(item["item"], potluck_item.taken_items.find_index({"id"=>attendee.id, "item"=>item["item"]}))
						end
					end
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
		def self.invite(email_list, event)
			email_hash = {"successful" => [], "unsuccessful" => [], "duplicated" => []}
			email_list.each do |email|
				if email.match(/^([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})$/i)
					attendee = Attendee.new(:event_id => event.id, :email => email, :rsvp => "Undecided")
					if attendee.save
						email_hash["successful"] << email
						Thread.new { AttendeeMailer.welcome_guest(attendee).deliver }
					else
						email_hash["duplicated"] << email
					end
				else
					email_hash["unsuccessful"] << email
				end
			end
			Thread.new { AttendeeMailer.send_host_guest_acknowledgement(email_hash, event).deliver }
			return email_hash
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
			return self.find_attendee_for(user, event).rsvp
		end
end
