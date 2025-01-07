# == Schema Information
#
# Table name: groups
#
#  id                :bigint           not null, primary key
#  false_information :boolean
#  kopfgeld          :integer
#  name              :string
#  points            :integer          default(0)
#  sort_order        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Group < ApplicationRecord
  has_many :events
  has_many :users

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "false_information", "id", "kopfgeld", "name", "points", "sort_order", "updated_at" ]
  end
  def self.ransackable_associations(auth_object = nil)
    [ "events", "users" ]
  end

  private

  def check_duplicate_users
    user_ids.each do |user_id|
      user = User.find(user_id)
      if user.group.present? && user.group != self
        errors.add(:base, "User #{user.email} is already assigned to another group.")
      end
    end
  end
end
