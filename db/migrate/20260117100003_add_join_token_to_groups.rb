class AddJoinTokenToGroups < ActiveRecord::Migration[7.1]
  def change
    add_column :groups, :join_token, :string
    add_column :groups, :name_editable, :boolean, default: true

    # Generate tokens for existing groups
    reversible do |dir|
      dir.up do
        Group.reset_column_information
        Group.find_each do |group|
          group.update_column(:join_token, SecureRandom.urlsafe_base64(12))
        end
      end
    end

    # Now make it non-nullable and add index
    change_column_null :groups, :join_token, false
    add_index :groups, :join_token, unique: true
  end
end
