# == Schema Information
#
# Table name: player_sessions
#
#  id                 :bigint           not null, primary key
#  device_fingerprint :string           not null
#  joined_at          :datetime
#  last_activity_at   :datetime
#  player_name        :string
#  session_token      :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  group_id           :bigint
#
# Indexes
#
#  index_player_sessions_on_device_fingerprint  (device_fingerprint) UNIQUE
#  index_player_sessions_on_group_id            (group_id)
#  index_player_sessions_on_session_token       (session_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (group_id => groups.id)
#
class PlayerSession < ApplicationRecord
  belongs_to :group, optional: true
  belongs_to :initial_group, class_name: 'Group', optional: true, foreign_key: 'initial_group_id'
  has_many :submissions

  before_create :generate_session_token

  validates :device_fingerprint, presence: true, uniqueness: true
  validates :session_token, presence: true, uniqueness: true

  # Ransack search attributes for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id player_name group_id joined_at last_activity_at created_at updated_at locked_to_group]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[group initial_group submissions]
  end

  # Find or create session from device fingerprint
  def self.find_or_create_from_device(device_fingerprint, player_name = nil)
    session = find_or_initialize_by(device_fingerprint: device_fingerprint) do |s|
      s.player_name = player_name
      s.generate_session_token
    end

    session.save if session.new_record?

    # Update activity
    session.update(last_activity_at: Time.current)
    session
  end

  # Join a group via join token
  # SECURITY: Prevents group hopping by locking device to first group
  def join_group!(join_token)
    group = Group.find_by(join_token: join_token)
    raise "Invalid join token" unless group

    # SECURITY: Check if session is blocked (rate limiting bypass)
    if blocked_until.present? && Time.current < blocked_until
      self.failed_join_attempts = (failed_join_attempts || 0) + 1
      save if changed?
      raise "Session temporarily blocked due to too many join attempts. Please try again later."
    end

    # SECURITY: Check for group hopping
    if locked_to_group && initial_group_id.present? && initial_group_id != group.id
      Rails.logger.warn("Group hopping attempt: Device #{device_fingerprint} tried to join group #{group.id} but locked to #{initial_group_id}")
      self.failed_join_attempts = (failed_join_attempts || 0) + 1
      
      # Block session after 3 failed attempts
      if failed_join_attempts >= 3
        self.blocked_until = 1.hour.from_now
      end
      
      save if changed?
      raise "Device is already locked to a group. Cannot switch groups."
    end

    # SECURITY: First join - lock to this group
    if group_id.nil?
      self.initial_group_id = group.id
      self.locked_to_group = true
    end

    update(
      group: group,
      joined_at: Time.current,
      last_activity_at: Time.current,
      failed_join_attempts: 0  # Reset failed attempts on success
    )
  end

  # Check if session is active (within last 30 minutes)
  def active?
    last_activity_at.present? && (Time.current - last_activity_at) < 30.minutes
  end

  # Check if session is blocked
  def blocked?
    blocked_until.present? && Time.current < blocked_until
  end

  # Check if session is currently locked to a group
  def group_locked?
    locked_to_group && initial_group_id.present?
  end

  # Reset block (admin function)
  def unblock!
    update(blocked_until: nil, failed_join_attempts: 0)
  end

  def generate_session_token
    self.session_token = SecureRandom.hex(32) unless session_token.present?
  end

  private
end
