# Player-facing controller for PWA
class PlayController < ApplicationController
  skip_before_action :authenticate_admin_user!, raise: false
  layout 'player'
  
  before_action :check_existing_session, only: [:join]
  before_action :require_player_session, only: [:home, :targets, :submit, :my_submissions]
  before_action :update_activity, only: [:home, :targets, :rules, :submit, :my_submissions]

  # GET /join/:token - QR code landing page
  def join
    @token = params[:token]
    @group = Group.find_by(join_token: @token)
    
    unless @group
      render :invalid_token and return
    end
    
    # Check if this device already has a session for THIS group
    existing = current_player_session
    if existing&.group == @group
      redirect_to play_home_path and return
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
    
    # Join group (allow switching groups if scanning new QR)
    session.group = @group
    session.joined_at = Time.current
    session.last_activity_at = Time.current
    
    if session.save
      # Set cookie for session persistence
      cookies[:player_session_token] = {
        value: session.session_token,
        expires: 7.days.from_now,
        httponly: true
      }
      
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
    @group = @session.group
  end

  # GET /play/rules - Rules page (public, no session required)
  def rules
    @session = current_player_session
    @options = Option.includes(:option_setting).all
  end

  # GET /play/targets - Target list
  def targets
    @group = @session.group
    @targets = Target.all
    @completed_targets = Event.where(group: @group, option: Option.find_by(name: "hat Posten geholt"))
                              .pluck(:target_id)
  end
  
  # GET /play/session_status - Check session status (AJAX)
  def session_status
    session = current_player_session
    if session&.group
      render json: {
        valid: true,
        group_name: session.group.name,
        player_name: session.player_name,
        points: session.group.player_visible_points
      }
    else
      render json: { valid: false }
    end
  end

  # GET /play/submit - Submission form
  def submit
    @group = @session.group
    # Exclude automatic options (like "hat Kopfgeld eingelöst" which is triggered automatically)
    @options = Option.where(active: true).includes(:option_setting).reject(&:automatic_option?)
    @target_groups = Group.where.not(id: @group.id).order(:name)
    @posten = Target.all.order(:name)
    
    # Get already verified targets for each option that requires a target
    posten_option = Option.find_by(name: 'hat Posten geholt')
    @verified_posten_ids = posten_option ? Submission.verified_target_ids(group_id: @group.id, option_id: posten_option.id) : []
    
    # Get existing submissions for duplicate checking (pending or verified, not denied)
    @existing_submissions = @group.submissions.where.not(status: 'denied').select(:option_id, :target_id, :target_group_id).map do |s|
      { option_id: s.option_id, target_id: s.target_id, target_group_id: s.target_group_id }
    end
  end

  # POST /play/submit - Process submission
  def create_submission
    @session = current_player_session
    unless @session&.group
      render json: { success: false, message: 'Session ungültig' }, status: :unauthorized
      return
    end

    # Parse incoming params and convert IDs to integers
    target_id = params[:target_id].presence
    target_group_id = params[:target_group_id].presence
    points_set = params[:points_set].presence

    # Convert string IDs to integers if present
    target_id = target_id&.to_i
    target_group_id = target_group_id&.to_i
    points_set = points_set&.to_i

    @submission = Submission.new(
      group: @session.group,
      player_session: @session,
      option_id: params[:option_id],
      target_id: target_id,
      target_group_id: target_group_id,
      points_set: points_set,
      description: params[:description]
    )

    # Handle photo upload
    if params[:photo].present?
      @submission.photo.attach(params[:photo])
    end

    if @submission.save
      render json: {
        success: true,
        message: 'Einreichung erfolgreich! Warte auf Bestätigung.',
        submission_id: @submission.id
      }
    else
      Rails.logger.error("Submission validation failed: #{@submission.errors.full_messages.inspect}")
      Rails.logger.error("  option_id=#{@submission.option_id}, target_group_id=#{@submission.target_group_id}, target_id=#{@submission.target_id}")
      Rails.logger.error("  requires_target_group?=#{@submission.requires_target_group?}, target_group=#{@submission.target_group.inspect}")
      render json: {
        success: false,
        message: @submission.errors.full_messages.join(', ')
      }, status: :unprocessable_entity
    end
  end

  # GET /play/submissions - My submissions list
  def my_submissions
    @group = @session.group
    @submissions = @session.submissions.recent.includes(:option, :target)
  end
  
  # DELETE /play/logout - Clear session
  def logout
    cookies.delete(:player_session_token)
    redirect_to root_path, notice: "Abgemeldet"
  end

  private
  
  # Redirect to /play if device already has valid session
  def check_existing_session
    session = current_player_session
    if session&.group && session.active?
      redirect_to play_home_path
    end
  end
  
  # Require valid session for protected pages
  def require_player_session
    @session = current_player_session
    unless @session&.group
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Bitte zuerst QR-Code scannen" }
        format.json { render json: { error: "Session ungültig" }, status: :unauthorized }
      end
    end
  end
  
  # Update last activity timestamp
  def update_activity
    session = current_player_session
    session&.update(last_activity_at: Time.current)
  end

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
