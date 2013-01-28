
class AttendeesController < ApplicationController
	before_filter :verify_access
	before_filter :verify_privileges, :except => :rsvp
	#Also, be sure to include a verification filter in which attendees can only update their settings (will have to check for attendee.user_id == current_user.id)
	#The reason why I did this was because I was getting a "WARNING: Can't verify CSRF token authenticity" and would sign the user out.

	protect_from_forgery :except => :invite_guests 
  # GET /attendees
  # GET /attendees.json
  def index
		@event = Event.find(params[:event_id])

    respond_to do |format|
      format.html # index.html.erb
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
		@attendee.rsvp = 'Undecided'
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
		@user = User.new

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

	def add_attendees
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
      format.html { redirect_to event_attendees_path }
      format.json { head :no_content }
    end
  end

	protected

	def verify_access
		event = Event.find(params[:event_id])
		unless current_user.belongs_to_event?(event)
			render file: "public/401.html" ,status: :unauthorized
		end
	end

	def verify_privileges
		event = Event.find(params[:event_id])
		unless current_user.is_host_for?(event)
			render file: "public/422.html", status: :unprocessable_entity
		end
	end


end
