
ActiveAdmin.register Group do
  permit_params :name, :description, :points, :false_information, :kopfgeld, user_ids: []

  form do |f|
    f.inputs do
      f.input :name
      f.input :points
      f.input :false_information
      f.input :kopfgeld
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
    column :kopfgeld
    column :false_information
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
      row :kopfgeld
      row :false_information
      row :description
      row :join_token
    end
    
    panel "QR Code für Gruppenbeitritt" do
      div style: "text-align: center; padding: 20px;" do
        h3 "Scanne diesen QR Code um der Gruppe beizutreten:"
        div id: "qrcode", style: "margin: 20px auto; display: inline-block;"
        
        script do
          raw %{
            var qrcode = new QRCode(document.getElementById("qrcode"), {
              text: "#{request.base_url}/join/#{group.join_token}",
              width: 256,
              height: 256
            });
          }
        end
        
        div style: "margin-top: 20px;" do
          strong "Join-Link: "
          code "#{request.base_url}/join/#{group.join_token}"
        end
      end
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
