class Group < ActiveRecord::Base
	belongs_to :user
	attr_accessible :user_id, :name, :email_distribution_list
	serialize :email_distribution_list

	before_validation do |group|
		group.email_distribution_list =  group.email_distribution_list.strip.split(",").map{|email| email.strip} unless group.email_distribution_list.blank? || group.email_distribution_list.is_a?(Array)
	end

	validates :user_id, :name, :email_distribution_list, :presence => true
	validate  :unique_emails, :unless => Proc.new{|group| group.email_distribution_list.blank? }

	def unique_emails
		errors.add(:email_distribution_list, " should only contain unique emails") unless self.email_distribution_list.uniq.count == self.email_distribution_list.count
	end

	def revert_for_controller
		self.email_distribution_list = self.email_distribution_list.join(",") unless self.email_distribution_list.blank?
	end
end
