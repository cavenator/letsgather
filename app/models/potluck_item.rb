class PotluckItem < ActiveRecord::Base
	belongs_to :event

	before_validation do |potluck_item|
		potluck_item.dishes = JSON.parse(potluck_item.dishes) unless potluck_item.dishes.is_a?(Array)
	end

	validates :event_id, :category, :host_quantity, :presence => true
	validates :dishes, :presence => true, :on => :create
	validates :host_quantity, :numericality => { :only_integer => true, :greater_than_or_equal_to => 0 }
	validates :category, :uniqueness => { :scope => :event_id, :message => "should be unique per event" }
	validate :verify_no_duplicates_dishes

	attr_accessible :event_id, :category, :dishes, :host_quantity, :taken_items
	serialize :dishes
	serialize :taken_items

	def remove_dish_from_list(index_for_available_item, taken_item_object)
		self.taken_items << taken_item_object
		self.dishes.delete_at(index_for_available_item)
		self.save
	end

	def make_item_available(dish, taken_item_index)
		self.dishes << dish
		self.taken_items.delete_at(taken_item_index)
		self.save
	end

	def verify_no_duplicates_dishes
		errors.add(:dishes, "No duplicates allowed in list") unless self.dishes.uniq.length == self.dishes.length
	end
end
