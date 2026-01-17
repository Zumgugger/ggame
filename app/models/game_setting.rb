# == Schema Information
#
# Table name: game_settings
#
#  id               :bigint           not null, primary key
#  default_values   :json
#  game_active      :boolean          default(FALSE)
#  game_end_time    :datetime
#  game_start_time  :datetime
#  point_multiplier :decimal(3, 2)    default(1.0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class GameSetting < ApplicationRecord
  has_many :game_time_windows, dependent: :destroy
  accepts_nested_attributes_for :game_time_windows, allow_destroy: true

  # Singleton pattern - only one row should exist
  validates :id, uniqueness: true, allow_nil: true

  # Ensure only one record exists
  def self.instance
    first_or_create!(point_multiplier: 1.0, game_active: false)
  end

  # Manually start the game
  def start_game!
    update!(game_active: true, game_start_time: Time.current)
  end

  # Manually stop the game
  def stop_game!
    update!(game_active: false, game_end_time: Time.current)
  end

  # Check if game is currently active
  def game_running?
    return false unless game_active
    
    # If time windows are defined, check if current time is in any window
    if game_time_windows.any?
      return game_time_windows.any?(&:active?)
    end
    
    # Fallback to simple start/end time
    now = Time.current
    starts = game_start_time || now
    ends = game_end_time || now + 1.year
    
    now >= starts && now <= ends
  end

  # Reset to default values
  def reset_to_defaults!
    defaults = default_values || {
      point_multiplier: 1.0,
      game_active: false,
      game_start_time: nil,
      game_end_time: nil
    }
    
    update!(defaults.symbolize_keys.slice(:point_multiplier, :game_active, :game_start_time, :game_end_time))
  end

  # Save current values as defaults
  def save_as_defaults!
    update!(default_values: {
      point_multiplier: point_multiplier,
      game_active: game_active,
      game_start_time: game_start_time,
      game_end_time: game_end_time
    })
  end
end
