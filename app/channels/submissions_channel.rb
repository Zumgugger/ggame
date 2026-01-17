# Channel for admin to receive real-time submission updates
class SubmissionsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "submissions_admin"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
