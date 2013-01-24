
class EventsController < ApplicationController
	before_filter :align_attendee_events, :only => :index
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
			Role.create(:user_id => current_user.id, :event_id => attendee_user.event_id, :privilege => "guest")
			attendee_user.save
		end
	end

end
