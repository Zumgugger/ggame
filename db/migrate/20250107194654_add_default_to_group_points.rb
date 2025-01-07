class AddDefaultToGroupPoints < ActiveRecord::Migration[7.0]
  def change
    change_column_default :groups, :points, from: nil, to: 0
  end
end
