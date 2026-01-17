# API Controller for player submissions
class Api::SubmissionsController < ApplicationController
  skip_forgery_protection # Mobile PWA won't have CSRF tokens
  before_action :authenticate_player!
  before_action :set_submission, only: [:show]

  # GET /api/submissions
  # List player's submissions
  def index
    submissions = @current_session.submissions.recent.includes(:option, :target, :group)
    
    render json: {
      submissions: submissions.map { |s| submission_json(s) }
    }
  end

  # GET /api/submissions/:id
  # Show single submission
  def show
    render json: submission_json(@submission)
  end

  # POST /api/submissions
  # Create a new submission
  def create
    @submission = Submission.new(submission_params)
    @submission.player_session = @current_session
    @submission.group = @current_session.group

    # Handle photo upload if present
    if params[:photo].present?
      @submission.photo.attach(params[:photo])
    end

    if @submission.save
      # Check if auto-verify is applicable
      if should_auto_verify?(@submission)
        @submission.verify!(nil, message: 'Automatisch verifiziert')
        render json: {
          success: true,
          message: 'Aktion erfolgreich eingereicht und automatisch bestätigt!',
          submission: submission_json(@submission),
          auto_verified: true
        }, status: :created
      else
        render json: {
          success: true,
          message: 'Aktion eingereicht! Warte auf Bestätigung.',
          submission: submission_json(@submission),
          auto_verified: false
        }, status: :created
      end
    else
      render json: {
        success: false,
        message: @submission.errors.full_messages.join(', '),
        errors: @submission.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/submissions/options
  # Get available options for submission form
  def options
    options = Option.where(active: true).includes(:option_setting)
    
    render json: {
      options: options.map do |opt|
        setting = opt.option_setting
        {
          id: opt.id,
          name: opt.name,
          requires_target: opt.requires_target?,
          requires_photo: setting&.requires_photo?,
          points: setting&.points || opt.count,
          rule_text: setting&.rule_text
        }
      end
    }
  end

  # GET /api/submissions/targets
  # Get available targets (other groups)
  def targets
    targets = Group.where.not(id: @current_session.group_id).order(:name)
    
    render json: {
      targets: targets.map do |t|
        {
          id: t.id,
          name: t.name,
          type: 'group'
        }
      end
    }
  end

  private

  def authenticate_player!
    token = request.headers['X-Session-Token'] || params[:session_token]
    @current_session = PlayerSession.find_by(session_token: token)

    unless @current_session&.group
      render json: {
        success: false,
        message: 'Ungültige Session. Bitte erneut beitreten.'
      }, status: :unauthorized
    end
  end

  def set_submission
    @submission = @current_session.submissions.find_by(id: params[:id])
    unless @submission
      render json: { success: false, message: 'Einreichung nicht gefunden' }, status: :not_found
    end
  end

  def submission_params
    params.permit(:option_id, :target_id, :description)
  end

  def submission_json(submission)
    {
      id: submission.id,
      option: {
        id: submission.option_id,
        name: submission.option.name
      },
      target: submission.target ? {
        id: submission.target_id,
        name: submission.target.name
      } : nil,
      status: submission.status,
      status_text: status_text(submission.status),
      description: submission.description,
      admin_message: submission.admin_message,
      submitted_at: submission.submitted_at.iso8601,
      verified_at: submission.verified_at&.iso8601,
      waiting_time: submission.waiting_time_text,
      has_photo: submission.photo.attached?
    }
  end

  def status_text(status)
    case status
    when 'pending' then 'Ausstehend'
    when 'verified' then 'Bestätigt'
    when 'denied' then 'Abgelehnt'
    else status
    end
  end

  def should_auto_verify?(submission)
    setting = OptionSetting.find_by(option: submission.option)
    # Auto-verify if option doesn't require photo and no photo was submitted
    return false if setting&.requires_photo?
    return false if submission.photo.attached?
    
    # Additional auto-verify logic can be added here
    # For now, non-photo options are NOT auto-verified to maintain admin control
    false
  end
end
