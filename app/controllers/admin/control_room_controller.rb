class Admin::ControlRoomController < ApplicationController
  before_action :authenticate_admin_user!
  layout 'admin'
  
  def index
    # Get earliest pending submission
    @submission_to_verify = Submission.where(status: 'pending')
                                      .order(created_at: :asc)
                                      .first

    # If no pending submission, show last event
    @last_event = Event.order(created_at: :desc).first

    # Queue statistics
    @pending_count = Submission.where(status: 'pending').count
    @verified_today = Submission.where(status: 'verified')
                                .where('created_at >= ?', Date.today)
                                .count
    @denied_today = Submission.where(status: 'denied')
                              .where('created_at >= ?', Date.today)
                              .count

    # Group rankings
    @groups = Group.all.order(points: :desc)

    # Recent events (last 10)
    @recent_events = Event.includes(:group, :option)
                           .order(created_at: :desc)
                           .limit(10)
  end

  def verify_submission
    @submission = Submission.find(params[:id])
    
    if @submission.verify!(current_admin_user, message: submission_params[:admin_message])
      render json: { success: true, message: 'Submission verified' }
    else
      render json: { success: false, message: @submission.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def deny_submission
    @submission = Submission.find(params[:id])
    
    if @submission.deny!(current_admin_user, message: submission_params[:admin_message])
      render json: { success: true, message: 'Submission denied' }
    else
      render json: { success: false, message: @submission.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def undo_submission
    @submission = Submission.find(params[:id])
    
    # Reset to pending
    if @submission.update(status: 'pending', admin_message: nil)
      render json: { success: true, message: 'Action undone' }
    else
      render json: { success: false, message: 'Could not undo action' }, status: :unprocessable_entity
    end
  end

  private

  def submission_params
    params.require(:submission).permit(:admin_message)
  end
end
