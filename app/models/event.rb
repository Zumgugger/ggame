# == Schema Information
#
# Table name: events
#
#  id                  :bigint           not null, primary key
#  description         :string
#  group_points        :integer
#  noticed             :boolean
#  points_set          :integer
#  target_group_points :integer
#  target_points       :integer
#  time                :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  group_id            :integer
#  option_id           :integer
#  target_group_id     :integer
#  target_id           :integer
#
class Event < ApplicationRecord
  belongs_to :group
  belongs_to :option
  belongs_to :target_group, class_name: "Group", optional: true
  belongs_to :target, optional: true  # Making target optional

  # Nested Attributes
  accepts_nested_attributes_for :target, :group

  def group_name
    group&.name || "-"
  end

  def option_name
    option&.name || "-"
  end

  def target_name
    target&.name || "-"
  end

  def event_description
    event&.description || "-"
  end


  def self.ransackable_attributes(auth_object = nil)
    [ "id", "created_at", "updated_at", "description", "group_id", "group_points", "noticed", "option_id", "points_set", "target_id", "target_points", "time" ]
  end

  # Define searchable associations for Ransack (if needed)
  def self.ransackable_associations(auth_object = nil)
    [] # If no associations are needed for search, leave it empty
  end
end
