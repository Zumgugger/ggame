# == Schema Information
#
# Table name: option_settings
#
#  id                   :bigint           not null, primary key
#  auto_verify          :boolean          default(TRUE)
#  available_to_players :boolean          default(TRUE)
#  cooldown_seconds     :integer          default(0)
#  cost                 :integer          default(0)
#  points               :integer          default(0)
#  requires_photo       :boolean          default(FALSE)
#  requires_target      :boolean          default(FALSE)
#  rule_text            :text
#  rule_text_default    :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  option_id            :bigint           not null
#
# Indexes
#
#  index_option_settings_on_option_id  (option_id)
#
# Foreign Keys
#
#  fk_rails_...  (option_id => options.id)
#
class OptionSetting < ApplicationRecord
  belongs_to :option

  validates :option_id, uniqueness: true

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["id", "option_id", "requires_photo", "requires_target", "auto_verify", "points", 
     "cost", "cooldown_seconds", "rule_text", "available_to_players", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["option"]
  end

  # Reset to default rule text
  def reset_rule_to_default!
    update!(rule_text: rule_text_default) if rule_text_default.present?
  end

  # Save current rule as default
  def save_rule_as_default!
    update!(rule_text_default: rule_text)
  end

  # Get cooldown in a human-readable format
  def cooldown_minutes
    cooldown_seconds / 60
  end

  def cooldown_minutes=(minutes)
    self.cooldown_seconds = minutes.to_i * 60
  end
end
