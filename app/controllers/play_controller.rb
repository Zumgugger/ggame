# Player-facing controller for PWA
class PlayController < ApplicationController
  skip_before_action :authenticate_admin_user!, raise: false
  layout 'player'

  # GET /join/:token - QR code landing page
  def join
    @token = params[:token]
    @group = Group.find_by(join_token: @token)
    
    unless @group
      render :invalid_token and return
    end
  end

  # POST /join/:token - Process join request
  def process_join
    @token = params[:token]
    @group = Group.find_by(join_token: @token)
    
    unless @group
      render json: { success: false, message: "Ungültiger Token" }, status: :not_found
      return
    end

    # Generate device fingerprint from request
    device_fingerprint = generate_device_fingerprint
    player_name = params[:player_name]

    # Find or create session
    session = PlayerSession.find_or_initialize_by(device_fingerprint: device_fingerprint)
    session.player_name = player_name if player_name.present?
    session.generate_session_token if session.new_record?
    
    # Join group
    session.group = @group
    session.joined_at = Time.current
    session.last_activity_at = Time.current
    
    if session.save
      render json: {
        success: true,
        session_token: session.session_token,
        group_name: @group.name,
        message: "Willkommen in #{@group.name}!"
      }
    else
      render json: { success: false, message: session.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  # GET /play - Main player home (requires session)
  def home
    @session = current_player_session
    unless @session&.group
      redirect_to root_path, alert: "Bitte zuerst QR-Code scannen"
      return
    end
    @group = @session.group
  end

  # GET /play/rules - Rules page
  def rules
    @session = current_player_session
    @options = Option.includes(:option_setting).all
  end

  # GET /play/targets - Target list
  def targets
    @session = current_player_session
    unless @session&.group
      redirect_to root_path, alert: "Bitte zuerst QR-Code scannen"
      return
    end
    @group = @session.group
    @targets = Target.all
    @completed_targets = Event.where(group: @group, option: Option.find_by(name: "hat Posten geholt"))
                              .pluck(:target_id)
  end

  private

  def generate_device_fingerprint
    # Simple fingerprint from User-Agent + IP (can be enhanced)
    "#{request.user_agent}_#{request.remote_ip}".hash.abs.to_s(36)
  end

  def current_player_session
    token = cookies[:player_session_token] || params[:session_token]
    return nil unless token
    PlayerSession.find_by(session_token: token)
  end
end
