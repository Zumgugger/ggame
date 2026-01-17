class EventsController < ApplicationController
  before_action :authenticate_admin_user!
  before_action :set_event, only: [ :show, :destroy ]


  def main
    @events = Event.includes(:group, :target, :option).order(created_at: :desc).limit(12).reverse
    @groups = Group.all.order(points: :desc)
    @title = "Control Room"
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
    @groups = Group.all.order(id: :asc)
    @options = Option.all.order(id: :asc)
    @targets = Target.all.order(id: :asc)
  end
  # POST /events
  def create
    @event = Event.new(event_params)  # Create a new event with the permitted parameters
    @event.calculate_points  # Delegate the calculation logic to the model

    if @event.save  # If the event is saved successfully
      redirect_to :main_path, notice: "Event was successfully created."  # Redirect to the newly created event's show page
    else
      # If the event fails to save, re-render the form with errors
      @groups = Group.all.order(id: :asc)  # Repopulate groups for the form
      @options = Option.all.order(id: :asc)   # Repopulate options for the form
      @targets = Target.all.order(id: :asc)   # Repopulate targets for the form
      render :new  # Render the form again to display errors
    end
  end

  # DELETE /events/1
  def destroy
    @event.destroy
    redirect_to events_url, notice: "Event was successfully destroyed."
  end

  # GET /groups/:id/qr_pdf
  # Download QR code as PDF
  def group_qr_pdf
    @group = Group.find(params[:id])
    
    # Generate QR code
    qr_url = "#{request.protocol}#{request.host}/api/player_sessions/join?token=#{@group.join_token}"
    qr = RQRCode::QRCode.new(qr_url, size: 10, level: :h)
    
    # Create PNG image
    qr_png = qr.as_png(size: 300)
    temp_file = Tempfile.new(['qr', '.png'], Rails.root.join('tmp'))
    temp_file.binmode
    temp_file.write(qr_png)
    temp_file.flush
    
    # Create PDF with prawn
    pdf = Prawn::Document.new
    pdf.font_size 24
    pdf.text @group.name, align: :center, style: :bold
    
    pdf.move_down 20
    
    # Add QR code to PDF
    pdf.image temp_file.path, width: 300, align: :center
    
    pdf.move_down 20
    pdf.font_size 12
    pdf.text "Token: #{@group.join_token}", align: :center, color: "666666"
    
    # Get PDF as string before cleanup
    pdf_content = pdf.render
    
    # Cleanup
    temp_file.close
    temp_file.unlink
    
    # Send PDF
    send_data pdf_content, filename: "#{@group.name}-QR-Code.pdf", type: "application/pdf"
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
