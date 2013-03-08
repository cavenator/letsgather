
class PotluckItemsController < ApplicationController
		before_filter :get_event
		before_filter :verify_privileges, :except => [:index]
		before_filter :verify_access, :only => [:index]

  # GET /potluck_items
  # GET /potluck_items.json
  def index
    @potluck_items = @event.potluck_items

    respond_to do |format|
      format.html { render :layout => false }# index.html.erb
      format.json { render json: @event.get_potluck_items_for_guests.to_json }
    end
  end

  # GET /potluck_items/1
  # GET /potluck_items/1.json
  def show
    @potluck_item = PotluckItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @potluck_item }
    end
  end

  # GET /potluck_items/new
  # GET /potluck_items/new.json
  def new
    @potluck_item = PotluckItem.new

    respond_to do |format|
      format.html { render :layout => false }# new.html.erb
      format.json { render json: @potluck_item }
    end
  end

  # GET /potluck_items/1/edit
  def edit
    @potluck_item = PotluckItem.find(params[:id])
		render :layout => false
  end

  # POST /potluck_items
  # POST /potluck_items.json
  def create
    @potluck_item = PotluckItem.new(params[:potluck_item])

    respond_to do |format|
      if @potluck_item.save
        format.html { redirect_to [@event, @potluck_item], notice: 'Potluck item was successfully created.' }
        format.json { render json: @potluck_item, status: :created, location: @potluck_item }
      else
        format.html { render action: "new" }
        format.json { render json: @potluck_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /potluck_items/1
  # PUT /potluck_items/1.json
  def update
    @potluck_item = PotluckItem.find(params[:id])

    respond_to do |format|
      if @potluck_item.update_attributes(params[:potluck_item])
        format.html { redirect_to [@event, @potluck_item], notice: 'Potluck item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @potluck_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /potluck_items/1
  # DELETE /potluck_items/1.json
  def destroy
    @potluck_item = PotluckItem.find(params[:id])
    @potluck_item.destroy

    respond_to do |format|
      format.html { redirect_to event_potluck_items_url }
      format.json { head :no_content }
    end
  end

	protected

	def get_event
		@event = Event.find(params[:event_id])
	end

	def verify_privileges
		unless current_user.is_host_for?(@event)
			render file: "public/422.html", :formats => [:html], status: :unprocessable_entity and return
		end
	end

	def verify_access
		unless current_user.belongs_to_event?(@event)
			render file: "public/401.html" , :formats => [:html], status: :unauthorized and return
		end
	end

end
