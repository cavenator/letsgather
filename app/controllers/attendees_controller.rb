
class AttendeesController < ApplicationController
	before_filter :verify_access, :except => [:thank_you]
	before_filter :verify_host_privileges, :only => [:new, :create, :add_attendees, :invite_guests, :send_updated_calendar, :send_individual_calendar ]
	before_filter :verify_correct_attendee, :only => [:show, :edit, :update, :destroy ]
	before_filter :verify_correct_rsvp, :only => [:rsvp]

  # GET /attendees
  # GET /attendees.json
  def index
		@event = Event.find(params[:event_id])

    respond_to do |format|
      format.html { render :layout => false }# index.html.erb 
      format.json { render json: @attendees }
    end
  end

	def rsvp
		logger.debug "Inside RSVP"
		@event = Event.find(params[:event_id])
		if current_user
			@attendee = Attendee.find_attendee_for(current_user, @event)
		else
			@attendee = get_current_guest
		end
		view = "rsvp"
		if @attendee.rsvp.eql?("No Response")
			view = "initial_rsvp"
		end
		render view, :layout => false
	end

  # GET /attendees/1
  # GET /attendees/1.json
  def show
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @attendee }
    end
  end

  # GET /attendees/new
  # GET /attendees/new.json
  def new
    @attendee = Attendee.new
		@event = Event.find(params[:event_id])

    respond_to do |format|
      format.html { render :layout => false } # new.html.erb
      format.json { render json: @attendee }
    end
  end

  # GET /attendees/1/edit
  def edit
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])
		render :layout => false
  end

  # POST /attendees
  # POST /attendees.json
  def create
    @attendee = Attendee.new(params[:attendee])
		@event = Event.find(params[:event_id])
		@attendee.event_id = @event.id
    respond_to do |format|
      if @attendee.save
				send_message_to(@attendee, current_user)
        format.html { redirect_to [@event,@attendee], notice: 'Attendee was successfully created.' }
        format.json { render json: @attendee, status: :created, location: @attendee }
      else
        format.html { render action: "new", status: :unprocessable_entity }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /attendees/1
  # PUT /attendees/1.json
  def update
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])
		@user = User.new
		error_message = String.new

    respond_to do |format|
      if @attendee.update_attributes(params[:attendee])
				if current_user
					if current_user.is_host_for?(@event)
						format.html { render :nothing => true, :status => 204 }
					else
						format.html { redirect_to event_url(@event), notice: 'RSVP was successfully updated.' }
					end
				else
					format.html { redirect_to thank_you_url, notice: 'Thank you for responding!'}
				end
        format.json { head :no_content }
      else
				@attendee.errors.full_messages.each do |message|
					error_message += " #{message}\n,"
				end
				if current_user.is_host_for?(@event)
					format.html { render :nothing => true, status: :unprocessable_entity }
					format.json { render json: @attendee.errors, status: :unprocessable_entity }
				else
					format.html { redirect_to event_url(@event), notice: "RSVP couldn't be updated since it did not receive any of the following responses:#{error_message.chop}" }
					format.json { render json: @attendee.errors, status: :unprocessable_entity }
				end
      end
    end
  end

	def other_guests
		@event = Event.find(params[:event_id])
		if current_user
			@attending = @event.attendees.where("rsvp = 'Going' and (user_id is null or user_id <> ?)", current_user.id)
			@not_going = @event.attendees.where("rsvp = 'Not Going' and (user_id is null or user_id <> ?)", current_user.id)
			@undecided = @event.attendees.where("rsvp = 'Undecided' and (user_id is null or user_id <> ?)", current_user.id)
			@no_response = @event.attendees.where("rsvp = 'No Response' and (user_id is null or user_id <> ?)", current_user.id)
		else
			@attending = @event.attendees.where("rsvp = 'Going' and id <> ?", get_current_guest.id)
			@not_going = @event.attendees.where("rsvp = 'Not Going' and id <> ?", get_current_guest.id)
			@undecided = @event.attendees.where("rsvp = 'Undecided' and id <> ?", get_current_guest.id)
			@no_response = @event.attendees.where("rsvp = 'No Response' and id <> ?", get_current_guest.id)
		end
		render :layout => false
	end

	def add_attendees
		@event = Event.find(params[:event_id])
		render :layout => false
	end

	def email_guest
		@event = Event.find(params[:event_id])
		@attendee = Attendee.find(params[:id])
		render :layout => false
	end

	def thank_you
		session[:attendee_id] = nil
		render :layout => "application"
	end

  def send_guest_email
		@event = Event.find(params[:event_id])
		@subject = params[:subject]
		@body = params[:body]
		@attendee = Attendee.find(params[:id])
		if current_user
			@sender = current_user
		else
			@sender = get_current_guest
		end
		if @subject.blank? || @body.blank?
			flash[:notice] = "You must include both a subject and body"
			render :action => :email_guest, :status => :not_acceptable
		else
			MessageMailer.delay.email_guest(@attendee, @subject, @body, @sender)
			render :action => :email_guest, :status => 200
		end
	end

	def send_updated_calendar
		@event = Event.find(params[:event_id])
		AttendeeMailer.delay.send_updated_calendar(@event)
		render :nothing => true, :status => 200
	end

	def send_individual_calendar
		@attendee = Attendee.find(params[:id])
		@attendee.invite_sent = true
		@attendee.ensure_authentication_token!
		AttendeeMailer.delay.welcome_guest(@attendee, current_user)
		render :nothing => true, :status => 200
	end

	def invite_guests
		@event = Event.find(params[:event_id])
		email_invites = JSON.parse(params[:email_invites])
		@invites = Attendee.invite(email_invites["email"], @event, current_user)
		respond_to do |format|
			format.html { render "invite_guests" }
      format.json  { render json: params[:email_invites] }
    end
	end

  # DELETE /attendees/1
  # DELETE /attendees/1.json
  def destroy
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])
    @attendee.destroy

    respond_to do |format|
      format.html { render :action => :index }
      format.json { head :no_content }
    end
  end

	protected

	def verify_access
		event = Event.find(params[:event_id])
		logger.debug "session is #{session[:attendee_id]}"
		logger.debug "current_attendee = #{current_attendee}"
		if current_user
			unless current_user.is_host_for?(event) || current_user.belongs_to_event?(event)
				render file: "public/401.html",layout: false, status: :unauthorized
			end
		else
			unless get_current_guest.event_id == event.id
				session[:attendee_id] = nil
				render file: "public/401.html" ,layout: false, status: :unauthorized
			end
		end
	end

	def send_message_to(attendee, inviter)
		unless attendee.email.blank?
			AttendeeMailer.delay.welcome_guest(attendee,inviter)
		end
	end

	def verify_host_privileges
		event = Event.find(params[:event_id])
		unless current_user && current_user.is_host_for?(event)
			render file: "public/422.html", layout: false, status: :unprocessable_entity
		end
	end

	def verify_correct_attendee
		event = Event.find(params[:event_id])
		attendee = Attendee.find(params[:id])
		if current_user
			unless current_user.is_host_for?(event) || attendee.user_id == current_user.id
				render file: "public/422.html", layout: false, status: :unprocessable_entity
			end
		else
			unless get_current_guest.id == attendee.id
				session[:attendee_id] = nil
				render file: "public/422.html", layout: false, status: :unprocessable_entity
			end
		end
	end

	def verify_correct_rsvp
		event = Event.find(params[:event_id])
		if current_user
			attendee = Attendee.find_attendee_for(current_user, event)
		else
			logger.debug "WTF is going on"
			attendee = get_current_guest
		end
		unless attendee
			session[:attendee_id] = nil
			render file: "public/422.html", layout:false, status: :unprocessable_entity
		end
	end
	
end
