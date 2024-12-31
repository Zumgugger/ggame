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

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "count", "created_at", "id", "name", "updated_at" ]
  end
end
