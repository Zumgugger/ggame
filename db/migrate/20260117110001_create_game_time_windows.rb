class CreateGameTimeWindows < ActiveRecord::Migration[7.1]
  def change
    create_table :game_time_windows do |t|
      t.references :game_setting, foreign_key: true, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :name
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :game_time_windows, [:game_setting_id, :position]
  end
end
