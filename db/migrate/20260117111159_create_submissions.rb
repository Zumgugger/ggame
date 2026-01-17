class CreateSubmissions < ActiveRecord::Migration[7.2]
  def change
    create_table :submissions do |t|
      t.references :group, foreign_key: true, null: false
      t.references :option, foreign_key: true, null: false
      t.references :target, foreign_key: true, null: true
      t.references :player_session, foreign_key: true, null: false
      t.string :status, default: 'pending', null: false
      t.text :description
      t.text :admin_message
      t.datetime :submitted_at, null: false
      t.datetime :verified_at
      t.references :verified_by, foreign_key: { to_table: :admin_users }, null: true

      t.timestamps
    end

    add_index :submissions, :status
    add_index :submissions, :submitted_at
    add_index :submissions, [:group_id, :option_id, :target_id], name: 'idx_submissions_unique_pending',
              where: "status = 'pending'"
  end
end
