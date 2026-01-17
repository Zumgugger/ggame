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
  has_one :option_setting, dependent: :destroy

  # Automatically create option_setting when option is created
  after_create :create_default_setting

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "count", "created_at", "id", "name", "updated_at" ]
  end

  private

  def create_default_setting
    OptionSetting.create!(option: self) unless option_setting
  end
end
