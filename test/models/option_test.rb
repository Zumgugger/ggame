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
require "test_helper"

class OptionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
