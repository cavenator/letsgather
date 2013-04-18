
class AttendeesController < ApplicationController
	before_filter :verify_access
	before_filter :verify_host_privileges, :only => [:new, :create, :add_attendees, :invite_guests ]
	before_filter :verify_correct_attendee, :only => [:rsvp, :show, :edit, :update, :destroy ]

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
		@attendee = Attendee.find(params[:id])
		@attendee.rsvp = params[:rsvp]
		if @attendee.save
			respond_to do |format|
				format.json { render json: @attendee.to_json }
			end
		else 
			respond_to do |format|
				format.json { render json: @attendee.errors, status: :unprocessable_entity }
			end
		end
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
				if current_user.is_host_for?(@event)
					format.html { render :nothing => true, :status => 204 }
				else
					format.html { redirect_to event_url(@event), notice: 'RSVP was successfully updated.' }
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

	def add_attendees
		@event = Event.find(params[:event_id])
		render :layout => false
	end

	def email_guest
		@event = Event.find(params[:event_id])
		@attendee = Attendee.find(params[:id])
		render :layout => false
	end

  def send_guest_email
		@event = Event.find(params[:event_id])
		@subject = params[:subject]
		@body = params[:body]
		@attendee = Attendee.find(params[:id])
		if @subject.blank? || @body.blank?
			flash[:notice] = "You must include both a subject and body"
			render :action => :email_guest, :status => :not_acceptable
		else
			Thread.new { AttendeeMailer.email_guest(@attendee, @subject, @body, current_user).deliver }
			render :action => :email_guest, :status => 200
		end

	end

	def invite_guests
		@event = Event.find(params[:event_id])
		email_invites = JSON.parse(params[:email_invites])
		@invites = Attendee.invite(email_invites["email"], @event)
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
		unless current_user.is_host_for?(event) || current_user.belongs_to_event?(event)
			render file: "public/401.html" ,status: :unauthorized
		end
	end

	def verify_host_privileges
		event = Event.find(params[:event_id])
		unless current_user.is_host_for?(event)
			render file: "public/422.html", status: :unprocessable_entity
		end
	end

	def verify_correct_attendee
		event = Event.find(params[:event_id])
		attendee = Attendee.find(params[:id])
		unless current_user.is_host_for?(event) || attendee.user_id == current_user.id
			render file: "public/422.html", status: :unprocessable_entity
		end
	end
end
