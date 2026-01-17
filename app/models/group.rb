# == Schema Information
#
# Table name: groups
#
#  id                :bigint           not null, primary key
#  false_information :boolean
#  join_token        :string           not null
#  kopfgeld          :integer
#  name              :string
#  name_editable     :boolean          default(TRUE)
#  points            :integer          default(0)
#  sort_order        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_groups_on_join_token  (join_token) UNIQUE
#
class Group < ApplicationRecord
  has_many :events
  has_many :users
  has_many :player_sessions
  has_many :submissions
  
  # Events where this group is the target (being photographed, etc.)
  has_many :targeted_events, class_name: 'Event', foreign_key: 'target_group_id'

  # Generate join token before validation
  before_validation :generate_join_token, on: :create

  validates :join_token, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "false_information", "id", "kopfgeld", "name", "name_editable", "points", "sort_order", "updated_at", "join_token" ]
  end
  def self.ransackable_associations(auth_object = nil)
    [ "events", "users" ]
  end

  # Generate QR code for joining
  def qr_code_url
    Rails.application.routes.url_helpers.join_url(token: join_token)
  end

  # Points visible to players - hides recent photo deductions until window expires
  # This prevents groups from knowing they were photographed by watching their points
  def player_visible_points
    # Find events where this group is the target and the deduction is still hidden
    hidden_deductions = targeted_events
      .where('hidden_until > ?', Time.current)
      .where.not(target_points: nil)
      .sum(:target_points)
    
    # Add back the hidden deductions (they're negative, so this shows higher points)
    points - hidden_deductions
  end

  private

  def generate_join_token
    self.join_token ||= SecureRandom.urlsafe_base64(12)
  end

  def check_duplicate_users
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user.group.present? && user.group != self
        errors.add(:base, "User #{user.email} is already assigned to another group.")
      end
    end
  end
end
