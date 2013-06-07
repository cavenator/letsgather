class EventSettingsController < ApplicationController
	#GET
	def get_settings
		@user = User.find(params[:user_id])
		respond_to do |format|
			format.html { render :layout => "events.html.erb" }
			format.json { render json: Settings.where("event_id in (?)", @user.events.map{|event| event.id}) << Settings.determineFutureSettings(@user) }
		end
	end

	#PUT
	def update_event_settings
		event_id = params[:event_id].to_i
		@user = User.find(params[:user_id])

		if event_id != 0
			@settings = Settings.find(params[:id])
			if @settings.update_attributes(Settings.merge(params[:settings]))
				render json: @settings, status: :ok
			else
				render :nothing => true, status: :unauthorized
			end
		else
			user_future_options = Settings.merge(params[:settings])
			@user.future_options = user_future_options.merge(Settings.AdditionalHashInfoForUser)
			if @user.save
				render json: @user.future_options, status: :ok
			else
				render :nothing => true, status: :unauthorized
			end
		end
	end
end
