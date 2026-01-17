class CreateGameSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :game_settings do |t|
      t.decimal :point_multiplier, default: 1.0, precision: 3, scale: 2
      t.datetime :game_start_time
      t.datetime :game_end_time
      t.boolean :game_active, default: false
      t.json :default_values

      t.timestamps
    end
  end
end
