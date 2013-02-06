
class PotluckItemsController < ApplicationController
		before_filter :get_event

  # GET /potluck_items
  # GET /potluck_items.json
  def index
    @potluck_items = @event.potluck_items

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @event.get_potluck_items_for_guests }
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
      format.html # new.html.erb
      format.json { render json: @potluck_item }
    end
  end

  # GET /potluck_items/1/edit
  def edit
    @potluck_item = PotluckItem.find(params[:id])
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
        format.html { redirect_to @potluck_item, notice: 'Potluck item was successfully updated.' }
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
end
