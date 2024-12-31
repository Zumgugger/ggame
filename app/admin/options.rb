ActiveAdmin.register Option do
  # Permit parameters for mass assignment
  permit_params :name, :count, :active

  # Index page customization
  index do
    selectable_column
    id_column
    column :name
    column :count
    column :active
    actions
  end

  # Form for creating and editing Options
  form do |f|
    f.inputs do
      f.input :name
      f.input :count
      f.input :active
    end
    f.actions
  end

  # Filter options
  filter :name
  filter :count
  filter :active
end
