class AddGroupToUsers < ActiveRecord::Migration[7.2]
  def change
    add_reference :users, :group, null: true, foreign_key: true
  end
end
