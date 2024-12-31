
ActiveAdmin.register Group do
  permit_params :name, :description, :points, :false_information, user_ids: []

  form do |f|
    f.inputs do
      f.input :name
      f.input :points
      f.input :false_information
      f.input :users, as: :check_boxes, collection: User.all, label: "Assign Users to Group"
    end
    f.actions
  end

  # Define the index page for groups (list of groups)
  index do
    selectable_column
    id_column
    column :name
    column :points
    column "Users" do |group|
      group.users.map(&:email).join(", ")  # Display the email of users in the group
    end
    actions
  end

  # Show page with users belonging to the group
  show do
    attributes_table do
      row :name
      row :points
      row :description
    end
    panel "Users in this Group" do
      table_for group.users do
        column :name
        column :email
        column :phone_number
      end
    end
    panel "Create New Group" do
      link_to "Create Group", new_admin_group_path, class: "button"
    end
  end

  controller do
    before_action :remove_group_from_users, only: [ :destroy ]

    def remove_group_from_users
      group = Group.find(params[:id])
      group.users.update_all(group_id: nil) # Unassign all users from the group
    end
  end
end
