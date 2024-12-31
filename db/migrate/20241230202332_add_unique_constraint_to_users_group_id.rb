class AddUniqueConstraintToUsersGroupId < ActiveRecord::Migration[7.2]
  def change
    def change
      add_index :users, :group_id, unique: true, where: "group_id IS NOT NULL"
    end
  end
end
