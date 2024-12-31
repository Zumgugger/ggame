class CreateEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :events do |t|
      t.datetime :time
      t.integer :group_id
      t.boolean :noticed
      t.integer :points_set
      t.integer :target_id
      t.string :description
      t.integer :target_group_id
      t.integer :group_points
      t.integer :target_points
      t.integer :target_group_points
      t.integer :option_id

      t.timestamps
    end
  end
end
