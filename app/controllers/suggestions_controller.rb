class SuggestionsController < ApplicationController
		before_filter :find_event
		before_filter :verify_access
		before_filter :prohibit_host, :only => [:new, :create]
		layout false

  # GET /suggestions
  # GET /suggestions.json
  def index
    @suggestions = @event.suggestions

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @suggestions }
    end
  end

  # GET /suggestions/1
  # GET /suggestions/1.json
  def show
    @suggestion = Suggestion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @suggestion }
    end
  end

  # GET /suggestions/new
  # GET /suggestions/new.json
  def new
    @suggestion = Suggestion.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @suggestion }
    end
  end

  # GET /suggestions/1/edit
  def edit
    @suggestion = Suggestion.find(params[:id])
  end

  # POST /suggestions
  # POST /suggestions.json
  def create
    @suggestion = Suggestion.new(params[:suggestion])
		@suggestion.event_id = @event.id
		@suggestion.requester_name = current_user.full_name
		@suggestion.requester_email = current_user.email

    respond_to do |format|
      if @suggestion.save
        format.html { render :nothing => true, :status => :created, notice: 'Suggestion was successfully created.' }
        format.json { render json: @suggestion, status: :created, location: [@event, @suggestion] }
      else
        format.html { render json: @suggestion.errors, status: :unprocessable_entity }
        format.json { render json: @suggestion.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /suggestions/1
  # PUT /suggestions/1.json
  def update
    @suggestion = Suggestion.find(params[:id])

    respond_to do |format|
      if @suggestion.update_attributes(params[:suggestion])
        format.html { redirect_to @suggestion, notice: 'Suggestion was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @suggestion.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /suggestions/1
  # DELETE /suggestions/1.json
  def destroy
    @suggestion = Suggestion.find(params[:id])
    @suggestion.destroy

    respond_to do |format|
      format.html { redirect_to suggestions_url }
      format.json { head :no_content }
    end
  end

	protected

	def find_event
		@user = current_user
		@event = Event.find(params[:event_id])
	end

	def prohibit_host
		if current_user.is_host_for?(@event)
			render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
		end
	end

	def verify_access
		unless current_user.is_host_for?(@event) || current_user.belongs_to_event?(@event)
			render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
		end
	end
	
end
