class ApplicationController < ActionController::Base
  protect_from_forgery
	before_filter :verify_which_user
	before_filter :clear_sessions, :only => [:sign_out]

	def verify_which_user
		if params[:auth_token] 
			authenticate_attendee!
			unless session[:attendee_id]
				session[:attendee_id] = current_attendee.id
			end
		elsif session[:attendee_id]
			@current_attendee = Attendee.find(session[:attendee_id])
		else
			if session[:attendee_id]
				session[:attendee_id] = nil
			end
			authenticate_user!
		end
  end

	def get_current_guest
		if session[:attendee_id]
			return Attendee.find(session[:attendee_id])
		else
			return current_attendee
		end
	end

end
