class EventSettingsController < ApplicationController
	#GET
	def get_settings
		@user = User.find(params[:user_id])
		render :layout => "events.html.erb"
	end
end
