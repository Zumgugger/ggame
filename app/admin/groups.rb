
ActiveAdmin.register Group do
  permit_params :name, :description, :points, :false_information, :kopfgeld

  # Define the index page for groups (list of groups)
  index do
    selectable_column
    id_column
    column :name
    column :points
    column :kopfgeld
    column :false_information
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
        
        if group.qr_code.attached?
          div style: "margin: 20px auto; display: inline-block;" do
            image_tag group.qr_code, style: "max-width: 300px; border: 2px solid #ddd; padding: 10px;"
          end
        else
          p "QR Code wird generiert..."
        end
        
        div style: "margin-top: 20px;" do
          strong "Join-Link: "
          code "#{request.base_url}/join/#{group.join_token}"
        end
      end
    end
  end

  controller do
    before_action :ensure_qr_code, only: :show

    def scoped_collection
      super
    end

    private

    def ensure_qr_code
      resource.ensure_qr_code!
    end
  end
end
