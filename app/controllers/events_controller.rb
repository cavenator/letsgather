
class EventsController < ApplicationController
	before_filter :verify_access, :except => [:index, :new, :create]
	before_filter :align_attendee_events, :only => :index
	before_filter :verify_privileges, :only => [:edit, :update, :destroy, :email_group, :send_group_email]
  # GET /events
  # GET /events.json
  def index
		attendee_event_ids = Attendee.where("user_id=?",current_user.id).map{|attendee| attendee.event_id }
		attendee_events = Event.find(attendee_event_ids)
		@events = current_user.events | attendee_events
	
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @events }
    end
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @event = Event.find(params[:id])
		view = 'show'
		unless current_user.is_host_for?(@event)
			view = 'guest_view'
			@attendee = Attendee.find_attendee_for(current_user, @event)
		end

    respond_to do |format|
      format.html { render view }# show.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/new
  # GET /events/new.json
  def new
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(params[:event])
		@event.user_id = current_user.id
    if @event.save
				Role.create(:user_id => current_user.id, :event_id => @event.id, :privilege => "host")
				respond_to do |format|
        	format.html { redirect_to @event, notice: 'Event was successfully created.' }
        	format.json { render json: @event, status: :created, location: @event }
  			end
		else
				respond_to do |format|
        	format.html { render action: "new" }
        	format.json { render json: @event.errors, status: :unprocessable_entity }
				end
    end
	end

  # PUT /events/1
  # PUT /events/1.json
  def update
    @event = Event.find(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

	def supplemental_info
		@event = Event.find(params[:id])
		render :layout => false
	end

	def group_email
		@event = Event.find(params[:id])
		@rsvp_group = params[:rsvp_group]
	end

	def email_host
		@event = Event.find(params[:id])
		@host = @event.user
	end

	def send_host_email
		@event = Event.find(params[:id])
		@host = @event.user
		@subject = params[:subject]
		@body = params[:body]
		if @subject.blank? || @body.blank?
			flash[:notice] = "You must include both a subject and body"
			redirect_to(:action => :email_host) and return
		else
			flash[:notice] = "Message to host has been sent"
			Thread.new { AttendeeMailer.email_host(@host, @event, @subject, @body, current_user.email).deliver }
			redirect_to(:action => :show) and return
		end
	end

	def send_group_email
		@event = Event.find(params[:id])
		@subject = params[:subject]
		@body = params[:body]
		@rsvp_group = params[:rsvp_group]
		if @subject.blank? || @body.blank? || @rsvp_group.blank?
			flash[:notice] = "You must include both a subject and body"
			redirect_to(:action => :group_email) and return
		else
			attendees = @event.attendees.where('rsvp = ?',@rsvp_group)
			Thread.new { AttendeeMailer.email_group(attendees, @event, @subject, @body).deliver }
			flash[:notice] = "Message to guests have been sent"
			redirect_to(:action => :show) and return
		end
	end

	def edit_supplemental_info
		@event = Event.find(params[:id])
		render :layout => false
	end

	def edit_location
		@event = Event.find(params[:id])
		render :layout => false
	end

	protected

	def align_attendee_events
		user_attendee_event = Attendee.where("user_id is null and email=?",current_user.email)
		user_attendee_event.each do |attendee_user|
			attendee_user.user_id = current_user.id
			attendee_user.full_name = current_user.full_name
			Role.create(:user_id => current_user.id, :event_id => attendee_user.event_id, :privilege => "guest")
			attendee_user.save
		end
	end

	def verify_access
		event = Event.find(params[:id])
		unless current_user.belongs_to_event?(event)
			render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
		end
	end

	def verify_privileges
		event = Event.find(params[:id])
		unless current_user.is_host_for?(event)
			render file: "public/422.html", :formats => [:html], status: :unprocessable_entity and return
		end
	end
end
