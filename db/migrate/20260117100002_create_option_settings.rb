class CreateOptionSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :option_settings do |t|
      t.references :option, foreign_key: true, null: false
      t.boolean :requires_photo, default: false
      t.boolean :requires_target, default: false
      t.boolean :auto_verify, default: true
      t.integer :points, default: 0
      t.integer :cost, default: 0
      t.integer :cooldown_seconds, default: 0
      t.text :rule_text
      t.text :rule_text_default
      t.boolean :available_to_players, default: true

      t.timestamps
    end

    # Only add index if it doesn't exist
    add_index :option_settings, :option_id, unique: true unless index_exists?(:option_settings, :option_id)
  end
end
