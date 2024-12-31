# == Schema Information
#
# Table name: groups
#
#  id                :bigint           not null, primary key
#  false_information :boolean
#  kopfgeld          :integer
#  name              :string
#  points            :integer
#  sort_order        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "test_helper"

class GroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
