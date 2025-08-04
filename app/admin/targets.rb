ActiveAdmin.register Target do
  # See permitted parameters documentation:
  # https://activeadmin.info/docs/9-forms.html

  config.sort_order = "id_asc"
  permit_params :name, :events, :description, :points, :mines, :count, :last_action, :village, :sort_order

  # Add a list of columns to show in the index page
  index do
    selectable_column
    id_column
    column :name
    column :description
    column :points
    column :mines
    column :count
    column :last_action
    column :village
    column :sort_order
    actions
  end

  # Form to add/edit targets
  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :points
      f.input :mines
      f.input :count
      f.input :last_action, as: :datetime_picker
      f.input :village
      f.input :sort_order
    end
    f.actions
  end
end
