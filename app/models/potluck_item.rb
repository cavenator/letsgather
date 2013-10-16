require 'csv'
class PotluckItem < ActiveRecord::Base
	belongs_to :event

	before_validation do |potluck_item|
		potluck_item.dishes = JSON.parse(potluck_item.dishes) unless potluck_item.dishes.is_a?(Array)
	end

	before_destroy do |potluck_item|
		return false unless potluck_item.taken_items.empty?
	end

	validates :event_id, :category, :host_quantity, :presence => true
	validates :host_quantity, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
	validates :category, :uniqueness => { :scope => :event_id, :message => "should be unique per event" }
	validate :verify_no_duplicates_dishes
	validate :verify_taken_item_still_present_in_available_list

	attr_accessible :event_id, :category, :dishes, :host_quantity, :taken_items
	serialize :dishes
	serialize :taken_items

	def remove_dish_from_list(dish, attendee_id)
		index_for_available_item = self.dishes.find_index(dish)
		taken_item_object = {"id" => attendee_id, "item" => dish}
		self.taken_items << taken_item_object
		self.dishes.delete_at(index_for_available_item)
		self.save
	end

	def make_item_available(dish, attendee_id)
		item_index = self.taken_items.find_index({"id"=> attendee_id, "item"=> dish})
		self.dishes << dish
		self.taken_items.delete_at(item_index)
		self.save
	end

	def initialize_taken_items
		if self.taken_items.blank?
			self.taken_items = []
		end
	end

	#this method returns the delta from the previous rsvp items and the current rsvp items
	#Sadly this method mutates teh state of the previous_items parameter and returns the modified state as a result
	#Find a cleaner way to do this
	def self.return_taken_list_delta(guest, event, previous_items)
		guest.dish.each do |item|
			potluck_item = event.get_potluck_list_per_category(item["category"])
			potluck_item.initialize_taken_items
			unless item["is_custom"] 
				if previous_items.blank? || previous_items.find_index(item).nil?
					potluck_item.remove_dish_from_list(item["item"], guest.id)
				elsif previous_items.find_index(item)
					previous_items.delete_at(previous_items.find_index(item))
				end
			end
		end
		previous_items
	end

	def self.make_items_available(guest, event, list)
		if list.blank?
			list = guest.dish
		end
		list.each do |remove_item|
			unless remove_item["is_custom"]
				potluck_item = event.get_potluck_list_per_category(remove_item["category"])
				potluck_item.make_item_available(remove_item["item"], guest.id)
			end
		end
	end

	def self.export_remaining_lists_from(potluck_items)
		available_items = potluck_items.select{|item| item.dishes.count > 0}.map{|item| [item.category, item.dishes] }
		CSV.generate do |csv|
			csv << ["Category","Item"]
			available_items.each do |category_item|
				category = category_item[0]
				category_item[1].each do |item|
					csv << [category, item]
				end
			end
		end
	end

	def verify_no_duplicates_dishes
		available_items = self.dishes.map{|a| a["item"]}
		errors.add(:dishes, "No duplicates allowed in list") unless available_items.uniq.length == available_items.length
	end

	def verify_taken_item_still_present_in_available_list
		self.taken_items.each do |item|
			errors.add(:dishes, "Cannot remove item from available selection since someone has RSVPed with it. You must remove it from that guest first before you can remove it") unless taken_items.blank? || !self.dishes.index{|x| x["item"].eql?(item["item"])}.blank?
		end
	end

	def self.build_from_suggestion(suggestion)
		if suggestion.new_or_existing.eql?("New")
			return PotluckItem.new(:event_id => suggestion.event_id, :category => suggestion.category, :dishes => suggestion.suggested_items, :host_quantity => 1)
		else
			potluck_item = suggestion.event.potluck_items.find{|item| item.category.eql?(suggestion.category)}
			potluck_item.dishes |= suggestion.suggested_items
			return potluck_item
		end
	end
end
