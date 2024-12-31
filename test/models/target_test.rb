# == Schema Information
#
# Table name: targets
#
#  id          :bigint           not null, primary key
#  count       :integer          default(0)
#  description :string
#  last_action :datetime
#  mines       :integer          default(0)
#  name        :string
#  points      :integer          default(100)
#  sort_order  :integer
#  village     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

class TargetTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
