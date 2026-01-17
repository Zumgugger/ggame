class CreatePlayerSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :player_sessions do |t|
      t.string :device_fingerprint, null: false
      t.string :session_token, null: false
      t.string :player_name
      t.references :group, foreign_key: true, null: true
      t.datetime :joined_at
      t.datetime :last_activity_at

      t.timestamps
    end

    # Indexes for fast lookup
    add_index :player_sessions, :device_fingerprint, unique: true
    add_index :player_sessions, :session_token, unique: true
  end
end
