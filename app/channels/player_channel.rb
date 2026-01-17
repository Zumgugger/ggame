# Channel for players to receive updates about their submissions and group
class PlayerChannel < ApplicationCable::Channel
  def subscribed
    # Stream to the player's specific group channel
    if params[:group_id].present?
      stream_from "player_group_#{params[:group_id]}"
    end
    
    # Stream to player's specific session for personal notifications
    if params[:session_token].present?
      stream_from "player_session_#{params[:session_token]}"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
