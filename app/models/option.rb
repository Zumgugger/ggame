# == Schema Information
#
# Table name: options
#
#  id         :bigint           not null, primary key
#  active     :boolean
#  count      :integer
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Option < ApplicationRecord
  has_many :events
  has_many :submissions
  has_one :option_setting, dependent: :destroy

  # Automatically create option_setting when option is created
  after_create :create_default_setting

  # Check if this option requires a target group selection (another group)
  def requires_target_group?
    target_group_options = [
      'hat Gruppe fotografiert',
      'hat spioniert',
      'hat Foto bemerkt',
      'hat Kopfgeld gesetzt'
    ]
    target_group_options.include?(name)
  end

  # Check if this option requires a Posten/Target selection
  def requires_posten?
    posten_options = [
      'hat Posten geholt',
      'hat Mine gesetzt',
      'hat sondiert',
      'hat Mine entschärft'
    ]
    posten_options.include?(name)
  end

  # Check if this option requires a points_set value (user enters amount)
  def requires_points_input?
    points_input_options = [
      'hat Mine gesetzt',
      'hat Kopfgeld gesetzt'
    ]
    points_input_options.include?(name)
  end

  # Check if this option is triggered automatically (not selectable by players)
  # Currently none - Kopfgeld collection is handled within "hat Gruppe fotografiert"
  def automatic_option?
    false
  end

  # Legacy method - returns true if either target type is needed
  def requires_target?
    requires_target_group? || requires_posten?
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "count", "created_at", "id", "name", "updated_at" ]
  end

  private

  def create_default_setting
    OptionSetting.create!(option: self) unless option_setting
  end
end
