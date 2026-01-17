class AddPointsSetToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :submissions, :points_set, :integer
  end
end
