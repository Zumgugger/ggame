class RemoveUsersGroupId < ActiveRecord::Migration[7.2]
  def change
    remove_index :users, name: :index_users_on_group_id, if_exists: true if index_exists?(:users, :group_id)
    remove_column :users, :group_id, :bigint if column_exists?(:users, :group_id)
  end
end
