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
require "test_helper"

class EventTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
