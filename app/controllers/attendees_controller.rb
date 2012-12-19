
class AttendeesController < ApplicationController

  # GET /attendees
  # GET /attendees.json
  def index
		@event = Event.find(params[:event_id])
		puts "Attendees count = #{@event.attendees.count}"

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @attendees }
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
      format.html # new.html.erb
      format.json { render json: @attendee }
    end
  end

  # GET /attendees/1/edit
  def edit
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])
  end

  # POST /attendees
  # POST /attendees.json
  def create
    @attendee = Attendee.new(params[:attendee])
		@event = Event.find(params[:event_id])
		@attendee.event_id = @event.id
		if (!User.find_by_email(@attendee.email).blank?)
			@attendee.rsvp = 'Undecided'
		else
			@attendee.rsvp = 'Invitation Pending'
		end
		puts "Inside create;  attendee = ${@attendee}"
    respond_to do |format|
      if @attendee.save
        format.html { redirect_to [@event,@attendee], notice: 'Attendee was successfully created.' }
        format.json { render json: @attendee, status: :created, location: @attendee }
      else
        format.html { render action: "new" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /attendees/1
  # PUT /attendees/1.json
  def update
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])

    respond_to do |format|
      if @attendee.update_attributes(params[:attendee])
        format.html { redirect_to [@event, @attendee], notice: 'Attendee was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @attendee.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /attendees/1
  # DELETE /attendees/1.json
  def destroy
    @attendee = Attendee.find(params[:id])
		@event = Event.find(params[:event_id])
    @attendee.destroy

    respond_to do |format|
      format.html { redirect_to event_attendees_path }
      format.json { head :no_content }
    end
  end

end
