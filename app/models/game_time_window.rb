# == Schema Information
#
# Table name: game_time_windows
#
#  id              :bigint           not null, primary key
#  end_time        :datetime         not null
#  name            :string
#  position        :integer          default(0)
#  start_time      :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  game_setting_id :bigint           not null
#
# Indexes
#
#  index_game_time_windows_on_game_setting_id               (game_setting_id)
#  index_game_time_windows_on_game_setting_id_and_position  (game_setting_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (game_setting_id => game_settings.id)
#
class GameTimeWindow < ApplicationRecord
  belongs_to :game_setting

  validates :start_time, :end_time, presence: true
  validate :end_time_after_start_time

  scope :ordered, -> { order(:position) }

  # Check if current time is within this window
  def active?
    now = Time.current
    now >= start_time && now <= end_time
  end

  def duration_hours
    ((end_time - start_time) / 3600).round(1)
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "muss nach der Startzeit liegen")
    end
  end
end
