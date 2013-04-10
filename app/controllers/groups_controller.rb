class GroupsController < ApplicationController
  # GET /groups
  # GET /groups.json
  def index
		@user = current_user
    @groups = current_user.groups

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.json
  def show
		@user = User.find(params[:user_id])
    @group = Group.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/new
  # GET /groups/new.json
  def new
		@user = current_user
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @group }
    end
  end

  # GET /groups/1/edit
  def edit
		@user = current_user
    @group = Group.find(params[:id])
  end

  # POST /groups
  # POST /groups.json
  def create
    @group = Group.new(params[:group])
		@group.user_id = params[:user_id]

    respond_to do |format|
      if @group.save
				flash[:notice] = "Group has been successfully created!"
        format.html { redirect_to :action => :show, :user_id => @group.user_id, :id => @group.id }
        format.json { render json: @group, status: :created, location: @group }
      else
				@group.revert_for_controller
				@user = current_user
        format.html { render action: "new" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /groups/1
  # PUT /groups/1.json
  def update
		@user = current_user
    @group = Group.find(params[:id])

    respond_to do |format|
      if @group.update_attributes(params[:group])
				flash[:notice] = 'Group was successfully updated!'
        format.html { redirect_to :action => :show, :user_id => @user.id, :id => @group.id}
        format.json { head :no_content }
      else
				@user = current_user
        format.html { render action: "edit" }
        format.json { render json: @group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.json
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.json { head :no_content }
    end
  end
end
