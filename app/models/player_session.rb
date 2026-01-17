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
  has_many :submissions

  before_create :generate_session_token

  validates :device_fingerprint, presence: true, uniqueness: true
  validates :session_token, presence: true, uniqueness: true

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
  def join_group!(join_token)
    group = Group.find_by(join_token: join_token)
    raise "Invalid join token" unless group

    update(group: group, joined_at: Time.current)
  end

  # Check if session is active (within last 30 minutes)
  def active?
    last_activity_at.present? && (Time.current - last_activity_at) < 30.minutes
  end

  def generate_session_token
    self.session_token = SecureRandom.hex(16) unless session_token.present?
  end

  private
end
