# Player join endpoint - called when device scans QR code
class Api::PlayerSessionsController < ApplicationController
  skip_forgery_protection # Mobile app won't have CSRF tokens

  # GET /api/player_sessions/:token/join
  # Join group via QR code token
  def join
    token = params[:token]
    device_fingerprint = request.headers['X-Device-Fingerprint'] || generate_fingerprint
    player_name = params[:player_name]

    begin
      # Find or create player session
      session = PlayerSession.find_or_create_from_device(device_fingerprint, player_name)
      
      # Join group
      session.join_group!(token)

      render json: {
        success: true,
        session_token: session.session_token,
        group: {
          id: session.group.id,
          name: session.group.name
        },
        message: "Willkommen in Gruppe #{session.group.name}!"
      }, status: :ok
    rescue => e
      render json: {
        success: false,
        message: e.message
      }, status: :unprocessable_entity
    end
  end

  # POST /api/player_sessions/create
  # Create or retrieve session for PWA
  def create
    device_fingerprint = request.headers['X-Device-Fingerprint'] || generate_fingerprint
    player_name = params[:player_name]

    session = PlayerSession.find_or_create_from_device(device_fingerprint, player_name)

    render json: {
      session_token: session.session_token,
      device_fingerprint: device_fingerprint,
      player_name: session.player_name,
      group_id: session.group_id,
      group_name: session.group&.name
    }, status: :ok
  end

  # PATCH /api/player_sessions/update_activity
  # Keep session alive
  def update_activity
    token = params[:session_token]
    session = PlayerSession.find_by(session_token: token)

    if session
      session.update(last_activity_at: Time.current)
      render json: { success: true }, status: :ok
    else
      render json: { success: false, message: "Session nicht gefunden" }, status: :not_found
    end
  end

  private

  def generate_fingerprint
    # Generate unique device fingerprint from User-Agent + IP
    "#{request.user_agent}_#{request.remote_ip}".hash.to_s
  end
end
