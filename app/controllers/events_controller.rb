class EventsController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_event, only: [ :show, :destroy ]


  def main
    @events = Event.includes(:group, :target, :option).order(created_at: :desc).limit(20)
    @groups = Group.all.order(points: :desc)
    @title = "Events"
  end

  # GET /events
  def index
    @events = Event.includes(:group, :target, :option).order(created_at: :desc)
    @title = "Events"
  end

  # GET /events/1
  def show
  end

  # GET /events/new
  def new
    @event = Event.new  # Initialize the event for the form
    @groups = Group.all.order(name: :asc)
    @options = Option.all.order(name: :asc)
    @targets = Target.all.order(sort_order: :asc)
  end
  # POST /events
  def create
    @event = Event.new(event_params)  # Create a new event with the permitted parameters

    if @event.save  # If the event is saved successfully
      redirect_to :main_path, notice: "Event was successfully created."  # Redirect to the newly created event's show page
    else
      # If the event fails to save, re-render the form with errors
      @groups = Group.all.order(points: :desc)  # Repopulate groups for the form
      @options = Option.all.order(name: :asc)   # Repopulate options for the form
      @targets = Target.all.order(name: :asc)   # Repopulate targets for the form
      render :new  # Render the form again to display errors
    end
  end

  # DELETE /events/1
  def destroy
    @event.destroy
    redirect_to events_url, notice: "Event was successfully destroyed."
  end

  private

  # Set the event instance
  def set_event
    @event = Event.find(params[:id])
  end

  # Define the strong parameters for creating/updating an event
  def event_params
    params.require(:event).permit(
      :description,
      :group_points,
      :noticed,
      :points_set,
      :target_group_points,
      :target_points,
      :time,
      :group_id,
      :option_id,
      :target_group_id,
      :target_id
    )
  end
end
