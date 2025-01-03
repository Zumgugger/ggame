ActiveAdmin.register AdminUser do
  permit_params :email, :phone_number, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :email
    column :phone_number
    column :current_sign_in_at
    column :sign_in_count
    column :created_at
    actions
  end

  filter :email
  filter :phone_number
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  form do |f|
    f.inputs do
      f.input :email
      f.input :phone_number
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
