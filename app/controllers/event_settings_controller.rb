class EventSettingsController < ApplicationController
	before_filter :verify_access

	#GET
	def get_settings
		@user = User.find(params[:user_id])
		@events = @user.events.where('start_date >= ?', Time.now)
		respond_to do |format|
			format.html { render :layout => "events.html.erb" }
			format.json { render json: Settings.where("event_id in (?)", @events.map{|event| event.id}) << Settings.determineFutureSettings(@user) }
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

	protected

	def verify_access
		user_id = params[:user_id]
		unless user_id.to_i == current_user.id
			render file: "public/401.html", :formats => [:html], status: :unauthorized and return
		end
	end

end
