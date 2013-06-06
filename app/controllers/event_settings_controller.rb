class EventSettingsController < ApplicationController
	#GET
	def get_settings
		@user = User.find(params[:user_id])
		respond_to do |format|
			format.html { render :layout => "events.html.erb" }
			format.json { render json: Settings.where("event_id in (?)", @user.events.map{|event| event.id}) }
		end
	end

	#PUT
	def update_event_settings
		event_id = params[:event_id].to_i
		@user = User.find(params[:user_id])
		unless event_id == 0
			@settings = Settings.find(params[:id])
			if @settings.update_attributes(params[:settings])
#				redirect_to :action => :get_settings, notice: 'Settings were successfully updated.' 
				render :nothing => true, status: :no_content
			else
#				render :action => :get_settings, notice: 'Settings were not updated! Here is are the problems:' + @settings.errors
				render :nothing => true, status: :unauthorized
			end
		end
	end
end
