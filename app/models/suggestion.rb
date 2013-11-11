class Suggestion < ActiveRecord::Base
	belongs_to :event

	attr_accessible :new_or_existing, :category, :suggested_items, :event_id, :requester_name, :requester_email

	before_validation do |suggestion|
		suggestion.suggested_items = JSON.parse(suggestion.suggested_items) unless suggestion.suggested_items.is_a?(Array)
	end

	serialize :suggested_items
	validates :event_id, :category, :new_or_existing, :requester_name, :requester_email, :presence => true
	validates :new_or_existing, :inclusion => { :in => ["New", "Existing"] , :message => "needs to be submitted with 'New','Existing'" }
	validates :category, :uniqueness => { :scope => :event_id, :message => "should be unique per event and if new list" }, :if => :verify_new_list_prequisities
	validate :verify_new_suggestions_criteria, :if => :verify_new_list_prequisities
	validate :verify_existing_list_criteria, :if => :verify_list_is_existing
	validate :uniqueness_of_suggested_items, :if => :verify_list_is_existing
	validates :suggested_items, :presence => true, :if => :verify_list_is_existing

	def verify_new_suggestions_criteria
		event = self.event
		errors.add(:category, "Category already exists! Please choose another one.") if event.potluck_items.map{|list| list.category.downcase}.include?(self.category)
		verify_no_duplicates_in_suggested_items
	end

	def verify_existing_list_criteria
		potluck_items = self.event.potluck_items.where("category = ?", self.category).first
		available_dishes = potluck_items.dishes.blank? ? [] : potluck_items.dishes.map{|item| item["item"]}
		existing_items = potluck_items.taken_items.map{|i| i["item"] } | available_dishes
		errors.add(:suggested_items, "Suggestion includes items that already exists for the event") unless existing_items.blank? || (existing_items.map{|item| item.downcase} & self.suggested_items.map{|item| item.downcase}).count == 0
		verify_no_duplicates_in_suggested_items
	end

	def uniqueness_of_suggested_items
		current_suggestions = self.event.suggestions.map{|suggestion| suggestion.suggested_items}.flatten
		errors.add(:suggested_items, "Suggestion already contains suggested items from another suggestion") unless ( current_suggestions & self.suggested_items ).count == 0
	end

	def verify_list_is_existing
		return self.new_or_existing.eql?("Existing") && !self.category.blank?
	end

	def verify_new_list_prequisities
		return self.new_or_existing.eql?("New") && !self.category.blank?
	end

	def verify_no_duplicates_in_suggested_items
		errors.add(:suggested_items, "No duplicates items allowed in new list") unless self.suggested_items.map{|item| item.downcase}.uniq.length == self.suggested_items.map{|item| item.downcase}.length
	end
end
