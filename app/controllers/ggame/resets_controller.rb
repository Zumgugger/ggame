class Ggame::ResetsController < ApplicationController
  before_action :authenticate_admin_user!
  def index
    # For now, this will just render a dummy view
  end
  def reset_mines
    Target.update_all(mines: 0)  # Reset mines to 0 for all targets
    redirect_to ggame_resets_path, notice: "Mines reset to 0 for all targets."
  end

  # Action to reset the count for all targets
  def reset_count
    Target.update_all(count: 0)
    redirect_to ggame_resets_path, notice: "Target count reset to 0 for all targets."
  end

  def reset_group_points
    Group.update_all(points: 0)
    redirect_to ggame_resets_path, notice: "All group points have been reset to 0."
  end

  def reset_kopfgeld
    Group.update_all(kopfgeld: 0)
    redirect_to ggame_resets_path, notice: "All Kopfgeld points have been reset to 0."
  end


  def destroy_all_users
    User.destroy_all
    redirect_to ggame_resets_path, notice: "All users have been deleted successfully."
  end
  def destroy_all_groups
    Group.destroy_all
    redirect_to ggame_resets_path, notice: "All groups have been deleted successfully."
  end
  def destroy_all_events
    Event.destroy_all
    redirect_to ggame_resets_path, notice: "All events have been deleted successfully"
  end
end
