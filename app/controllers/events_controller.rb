
class EventsController < ApplicationController
	before_filter :verify_access, :except => [:index, :new, :create, :faq]
	before_filter :align_attendee_events, :only => :index
	before_filter :verify_privileges, :only => [:edit, :update, :destroy, :email_group, :send_group_email]
	before_filter :get_current_user, :only => [:index, :new, :show, :edit, :update]

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
#				Role.create(:user_id => current_user.id, :event_id => @event.id, :privilege => "host")
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

		if !params[:event][:description].nil? || !params[:event][:theme].nil?
			render_command = { :partial=>"description", :locals => {:event => @event } }
		elsif !params[:event][:address1].nil? || !params[:event][:address2].nil? || !params[:event][:city].nil? || !params[:event][:state].nil? || !params[:event][:zip_code].nil?
			render_command = { :partial => "location", :locals => {:event => @event } }
		else
			render_command = { :action => :show, :notice => 'Event has been updated' }
		end

    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { render render_command }
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

	def remove_from_event
		@event = Event.find(params[:id])
		user = User.find(params[:user_id])
		@attendee = Attendee.find_attendee_for(user, @event)
		if @attendee.destroy
			message = "You have successfully removed yourself from the event #{@event.name}"
		else
			message = "Unsuccessful attempt of removing yourself from the event #{@event.name}. Please contact your administrator!"
		end
		redirect_to events_url, notice: message
	end

	def supplemental_info
		@event = Event.find(params[:id])
		render :layout => false
	end

	def description
		@event = Event.find(params[:id])
		render :layout => false
	end

	def group_email
		@event = Event.find(params[:id])
		@rsvp_group = params[:rsvp_group]
		render :layout => false
	end

	def email_host
		@event = Event.find(params[:id])
		@host = @event.user
		render :layout => false
	end

	def get_host_groups
		@event = Event.find(params[:id])
		@groups = @event.user.groups
		respond_to do |format|
			format.html { render :partial=> "/attendees/add_from_groups", :locals => { :user => @event.user }, :layout => false }
			format.json { render json: @groups }
		end
	end

	def send_host_email
		@event = Event.find(params[:id])
		@host = @event.user
		@subject = params[:subject]
		@body = params[:body]
		if @subject.blank? || @body.blank?
			render :action => :email_host, :status => :not_acceptable
		else
			Thread.new { AttendeeMailer.email_host(@host, @event, @subject, @body, current_user).deliver }
			render :nothing=>true, :status => 200
		end
	end

	def send_group_email
		@event = Event.find(params[:id])
		@subject = params[:subject]
		@body = params[:body]
		@rsvp_group = params[:rsvp_group]
		if @subject.blank? || @body.blank?
			flash[:notice] = "You must include both a subject and body"
			render :nothing => true, status: :not_acceptable
		else
			if @rsvp_group.blank?
				attendees = @event.attendees
			else
				attendees = @event.attendees.where('rsvp = ?',@rsvp_group)
			end
			Thread.new { AttendeeMailer.email_group(attendees, @event, @subject, @body).deliver }
			flash[:notice] = "Message to guests have been sent"
			render :nothing=>true, :status => 200
		end
	end

	def edit_supplemental_info
		@event = Event.find(params[:id])
		render :layout => false
	end

	def attending_guests
		@event = Event.find(params[:id])
		render :layout => false
	end

	def unattending_guests
		@event = Event.find(params[:id])
		render :layout => false
	end

	def undecided_guests
		@event = Event.find(params[:id])
		render :layout => false
	end

	def potluck_statistics
		@event = Event.find(params[:id])
		render :layout => false
	end

	def edit_location
		@event = Event.find(params[:id])
		render :layout => false
	end

	def faq
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
		unless current_user.is_host_for?(event)|| current_user.belongs_to_event?(event)
			render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
		end
	end

	def verify_privileges
		event = Event.find(params[:id])
		unless current_user.is_host_for?(event)
			render file: "public/422.html", :formats => [:html], status: :unprocessable_entity and return
		end
	end

	def get_current_user
		@user = current_user
	end
end
