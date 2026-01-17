class AddTargetGroupToSubmissions < ActiveRecord::Migration[7.2]
  def change
    add_reference :submissions, :target_group, null: true, foreign_key: { to_table: :groups }
  end
end
