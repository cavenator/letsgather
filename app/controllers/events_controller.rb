
class EventsController < ApplicationController
	before_filter :get_current_attendee
	before_filter :align_attendee_events, :only => [:index, :show]
	before_filter :verify_access, :except => [:index, :new, :create, :faq]
	before_filter :verify_privileges, :only => [:edit, :update, :destroy, :group_email, :send_group_email, :change_roles, :export_remaining_items]
	before_filter :verify_registered_user, :only => [:index, :new, :create]
	before_filter :get_current_user, :only => [:index, :new, :show, :edit, :update, :guests]

  # GET /events
  # GET /events.json
  def index
		if current_user
			attendee_event_ids = Attendee.where("user_id=?",current_user.id).map{|attendee| attendee.event_id }
			attendee_events = Event.where('id in (?) and end_date > ?', attendee_event_ids, Time.now.utc)
			@events = current_user.events.where('end_date > ?', Time.now.utc) | attendee_events
		elsif current_attendee
			@events = [] << current_attendee.event
		end

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
		appropriate_layout = "events"
		unless current_user && current_user.is_host_for?(@event) 
			view = 'guest_view'
			if current_user
				@attendee = Attendee.find_attendee_for(current_user, @event)
			else
				appropriate_layout = "guests"
				@attendee = current_attendee
			end
		end

    respond_to do |format|
      format.html { render view, :layout=>appropriate_layout }# show.html.erb
      format.json { render json: @event }
    end
  end

  # GET /events/new
  # GET /events/new.json
  def new
    @event = Event.new
		@event.settings = Settings.new

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
		@user = current_user
		@event.user_id = @user.id
    if @event.save
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

	def export_remaining_items
		potluck_items = Event.find(params[:id]).potluck_items
		send_data PotluckItem.export_remaining_lists_from(potluck_items), :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=remaining_items_for_my_event.csv"
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
		@hosts = @event.get_hosts
		@subject = params[:subject]
		@body = params[:body]
		if current_user
			@sender = current_user
		else
			@sender = get_current_guest
		end
		if @subject.blank? || @body.blank?
			render :action => :email_host, :status => :not_acceptable
		else
			MessageMailer.delay.email_host(@hosts, @event, @subject, @body, @sender)
			render :nothing=>true, :status => 200
		end
	end

	def send_group_email
		@event = Event.find(params[:id])
		@subject = params[:subject]
		@body = params[:body]
		@rsvp_group = params[:rsvp_group]
		@sender = current_user
		if @subject.blank? || @body.blank?
			flash[:notice] = "You must include both a subject and body"
			render :nothing => true, status: :not_acceptable
		else
			if @rsvp_group.blank?
				attendees = @event.attendees
			else
				attendees = @event.attendees.where('rsvp = ?',@rsvp_group)
			end
			email_list = attendees.map(&:email).compact
			MessageMailer.delay.email_group(email_list, @event, @subject, @body, @sender)
			flash[:notice] = "Message to guests have been sent"
			render :nothing=>true, :status => 200
		end
	end

	def edit_supplemental_info
		@event = Event.find(params[:id])
		render :layout => false
	end

	def taken_items
		@event = Event.find(params[:id])
		render :layout=>false, :partial=> "taken_items", :collection => @event.get_items_guests_are_bringing
	end

	def available_items
		@event = Event.find(params[:id])
		render :layout=>false, :partial=> "available_items", :collection => @event.get_available_items_for_event
	end

	def guests
		@event = Event.find(params[:id])
		@attending = @event.attendees.where("rsvp = 'Going'")
		@not_going = @event.attendees.where("rsvp = 'Not Going'")
		@undecided = @event.attendees.where("rsvp = 'Undecided'")
		@no_response = @event.attendees.where("rsvp = 'No Response'")
		render :layout => false
	end

	def potluck_statistics
		@event = Event.find(params[:id])
		render :layout => false
	end

	def change_roles
		@event = Event.find(params[:id])
		@attendee = Attendee.find(params[:attendee_id])
		verdict = @attendee.change_roles_and_notify(current_user)

		if verdict
			render :nothing => true, :status => :no_content
		else
			render :nothing => true, :status => :unprocessable_entity
		end
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
		unless @attendee
			user_attendee_event = Attendee.where("user_id is null and email=?",current_user.email)
			user_attendee_event.each do |attendee_user|
				attendee_user.user_id = current_user.id
				attendee_user.full_name = current_user.full_name
				if attendee_user.is_host
					Role.create(:user_id => current_user.id, :event_id => attendee_user.event_id, :privilege => Role.HOST)
				else
					Role.create(:user_id => current_user.id, :event_id => attendee_user.event_id, :privilege => Role.GUEST)
				end
				attendee_user.save
			end
		end
	end

	def verify_access
		event = Event.find(params[:id])
		if current_user
			unless current_user.is_host_for?(event)|| current_user.belongs_to_event?(event)
				render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
			end
		elsif @attendee
			unless @attendee.event_id == event.id
				render file: "public/401.html" , :layout=>false, :formats => [:html], status: :unauthorized and return
			end
		end
	end

	def verify_registered_user
		unless current_user
			session[:attendee_id] = nil
			render file: "public/401.html", :layout=>false, :formats => [:html], status: :unauthorized and return
		end
	end

	def verify_privileges
		event = Event.find(params[:id])
		unless current_user && current_user.is_host_for?(event)
			session[:attendee_id] = nil
			render file: "public/422.html", :layout=>false, :formats => [:html], status: :unprocessable_entity and return
		end
	end

	def get_current_user
		@user = current_user
	end

	def get_current_attendee
		@attendee = get_current_guest
	end

end
