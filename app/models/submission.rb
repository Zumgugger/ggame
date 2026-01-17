# == Schema Information
#
# Table name: submissions
#
#  id                :bigint           not null, primary key
#  admin_message     :text
#  description       :text
#  points_set        :integer
#  status            :string           default("pending"), not null
#  submitted_at      :datetime         not null
#  verified_at       :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  group_id          :bigint           not null
#  option_id         :bigint           not null
#  player_session_id :bigint           not null
#  target_group_id   :bigint
#  target_id         :bigint
#  verified_by_id    :bigint
#
# Indexes
#
#  idx_submissions_unique_pending          (group_id,option_id,target_id) WHERE ((status)::text = 'pending'::text)
#  index_submissions_on_group_id           (group_id)
#  index_submissions_on_option_id          (option_id)
#  index_submissions_on_player_session_id  (player_session_id)
#  index_submissions_on_status             (status)
#  index_submissions_on_submitted_at       (submitted_at)
#  index_submissions_on_target_group_id    (target_group_id)
#  index_submissions_on_target_id          (target_id)
#  index_submissions_on_verified_by_id     (verified_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#  fk_rails_...  (option_id => options.id)
#  fk_rails_...  (player_session_id => player_sessions.id)
#  fk_rails_...  (target_group_id => groups.id)
#  fk_rails_...  (target_id => targets.id)
#  fk_rails_...  (verified_by_id => admin_users.id)
#
class Submission < ApplicationRecord
  # Status constants
  STATUSES = %w[pending verified denied].freeze

  # Associations
  belongs_to :group
  belongs_to :option
  belongs_to :target, optional: true                    # Posten (from targets table)
  belongs_to :target_group, class_name: 'Group', optional: true  # Target group (for group actions)
  belongs_to :player_session
  belongs_to :verified_by, class_name: 'AdminUser', optional: true

  # Photo attachment via ActiveStorage
  has_one_attached :photo

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :submitted_at, presence: true
  validates :target, presence: true, if: :requires_posten?
  validates :target_group, presence: true, if: :requires_target_group?
  validates :points_set, presence: true, numericality: { greater_than: 0 }, if: :requires_points_input?
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
  after_create_commit :broadcast_new_submission
  after_update_commit :broadcast_status_change, if: :saved_change_to_status?

  # Verify the submission and create an Event
  def verify!(admin_user, message: nil)
    return false if status != 'pending'

    transaction do
      # Create the Event with correct target types
      event = Event.new(
        group: group,
        option: option,
        target: target,                # Posten (from targets table)
        target_group: target_group,    # Target group (for group actions like "hat Gruppe fotografiert")
        points_set: points_set         # Points for Mine/Kopfgeld
      )
      
      # Calculate points and set timestamp from submission time (not verification time)
      event.calculate_points(submitted_at: submitted_at)
      event.save!

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

  # Check if this option requires a Posten (Target)
  def requires_posten?
    option&.requires_posten?
  end

  # Check if this option requires a target group
  def requires_target_group?
    option&.requires_target_group?
  end

  # Check if this option requires points input (Mine/Kopfgeld)
  def requires_points_input?
    option&.requires_points_input?
  end

  # Legacy method
  def requires_target?
    option&.requires_target?
  end

  # Display name for the submission
  def display_name
    parts = [group.name, option.name]
    parts << target.name if target.present?
    parts << target_group.name if target_group.present?
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
    %w[id group_id option_id target_id target_group_id player_session_id status description admin_message 
       submitted_at verified_at verified_by_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[group option target target_group player_session verified_by photo_attachment photo_blob]
  end

  private

  def set_submitted_at
    self.submitted_at ||= Time.current
  end

  def cooldown_respected
    return unless option && group

    checker = CooldownChecker.new(group, option, target)
    result = checker.check
    unless result[:allowed]
      errors.add(:base, result[:reason] || "Cooldown aktiv.")
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

  # Broadcast new submission to admin queue
  def broadcast_new_submission
    ActionCable.server.broadcast("submissions_admin", {
      type: "new_submission",
      submission: {
        id: id,
        group_name: group.name,
        option_name: option.name,
        target_name: target&.name,
        target_group_name: target_group&.name,
        player_name: player_session&.player_name,
        has_photo: photo.attached?,
        submitted_at: submitted_at.strftime('%H:%M:%S'),
        waiting_time: waiting_time_text
      }
    })
  end

  # Broadcast status change to player
  def broadcast_status_change
    # Notify the specific player session
    ActionCable.server.broadcast("player_session_#{player_session.session_token}", {
      type: "submission_update",
      submission: {
        id: id,
        status: status,
        option_name: option.name,
        admin_message: admin_message,
        verified_at: verified_at&.strftime('%H:%M:%S')
      }
    })

    # Notify the admin that a submission was processed (for queue update)
    ActionCable.server.broadcast("submissions_admin", {
      type: "submission_processed",
      submission_id: id,
      status: status
    })

    # If verified, notify player's group about potential points change
    if status == 'verified'
      ActionCable.server.broadcast("player_group_#{group_id}", {
        type: "points_update",
        points: group.player_visible_points
      })

      # Also notify target group if applicable (their points may have changed)
      if target_group_id.present?
        ActionCable.server.broadcast("player_group_#{target_group_id}", {
          type: "points_update",
          points: target_group.player_visible_points
        })
      end
    end
  end
end
