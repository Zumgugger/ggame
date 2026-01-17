# == Schema Information
#
# Table name: submissions
#
#  id                :bigint           not null, primary key
#  group_id          :bigint           not null
#  option_id         :bigint           not null
#  target_id         :bigint
#  player_session_id :bigint           not null
#  status            :string           default("pending"), not null
#  description       :text
#  admin_message     :text
#  submitted_at      :datetime         not null
#  verified_at       :datetime
#  verified_by_id    :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Submission < ApplicationRecord
  # Status constants
  STATUSES = %w[pending verified denied].freeze

  # Associations
  belongs_to :group
  belongs_to :option
  belongs_to :target, optional: true
  belongs_to :player_session
  belongs_to :verified_by, class_name: 'AdminUser', optional: true

  # Photo attachment via ActiveStorage
  has_one_attached :photo

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :submitted_at, presence: true
  validates :target, presence: true, if: :requires_target?
  validate :cooldown_respected, on: :create
  validate :game_must_be_active, on: :create
  validate :photo_required_if_option_requires_photo, on: :create

  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :verified, -> { where(status: 'verified') }
  scope :denied, -> { where(status: 'denied') }
  scope :recent, -> { order(submitted_at: :desc) }
  scope :oldest_first, -> { order(submitted_at: :asc) }

  # Callbacks
  before_validation :set_submitted_at, on: :create

  # Verify the submission and create an Event
  def verify!(admin_user, message: nil)
    return false if status != 'pending'

    transaction do
      # Create the Event
      event = Event.create!(
        group: group,
        option: option,
        target: target
      )

      # Update submission
      update!(
        status: 'verified',
        verified_at: Time.current,
        verified_by: admin_user,
        admin_message: message
      )

      event
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Event konnte nicht erstellt werden: #{e.message}")
    false
  end

  # Deny the submission
  def deny!(admin_user, message: nil)
    return false if status != 'pending'

    update!(
      status: 'denied',
      verified_at: Time.current,
      verified_by: admin_user,
      admin_message: message.presence || 'Abgelehnt'
    )
  end

  # Check if this option requires a target
  def requires_target?
    option&.requires_target?
  end

  # Display name for the submission
  def display_name
    parts = [group.name, option.name]
    parts << target.name if target.present?
    parts.join(' → ')
  end

  # Time since submission
  def waiting_time
    return nil unless submitted_at
    Time.current - submitted_at
  end

  # Formatted waiting time
  def waiting_time_text
    return '-' unless waiting_time

    minutes = (waiting_time / 60).to_i
    if minutes < 60
      "#{minutes} Min."
    else
      hours = minutes / 60
      mins = minutes % 60
      "#{hours}h #{mins}m"
    end
  end

  # Ransackable attributes for ActiveAdmin search
  def self.ransackable_attributes(auth_object = nil)
    %w[id group_id option_id target_id player_session_id status description admin_message 
       submitted_at verified_at verified_by_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[group option target player_session verified_by photo_attachment photo_blob]
  end

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def cooldown_respected
    return unless option && group

    checker = CooldownChecker.new(option, group, target)
    unless checker.can_submit?
      remaining = checker.remaining_cooldown_minutes
      errors.add(:base, "Cooldown aktiv. Noch #{remaining} Minuten warten.")
    end
  end

  def game_must_be_active
    setting = GameSetting.instance
    unless setting.game_running?
      errors.add(:base, 'Das Spiel läuft gerade nicht.')
    end
  end

  def photo_required_if_option_requires_photo
    return unless option

    option_setting = OptionSetting.find_by(option: option)
    if option_setting&.requires_photo? && !photo.attached?
      errors.add(:photo, 'ist für diese Option erforderlich')
    end
  end
end
