class InventoryCount < ActiveRecord::Base
	belongs_to :event
  # attr_accessible :title, :body
		attr_accessible :event_id, :app_count, :main_dish_count, :sides_count, :salads_count, :desserts_count, :drinks_count

	validates :app_count,:main_dish_count,:sides_count,:salads_count,:desserts_count,:drinks_count, :presence => true
	validates :app_count, :numericality => true
end
