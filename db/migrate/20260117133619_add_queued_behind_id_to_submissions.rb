class AddQueuedBehindIdToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_column :submissions, :queued_behind_id, :bigint
    add_column :submissions, :queue_reason, :string
    add_index :submissions, :queued_behind_id
    add_foreign_key :submissions, :submissions, column: :queued_behind_id, on_delete: :nullify
  end
end
