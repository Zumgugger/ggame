# edited by my
#
ActiveAdmin.register User do
  permit_params :group_id, :email, :phone_number, :created_at, :updated_at, :sign_in_count

  index do
    selectable_column
    id_column
    column :group, sortable: "groups.name" do |user|
      user.group&.name || "No Group"
    end
    column :email
    column :phone_number
    column :created_at
    column :updated_at
    column :sign_in_count

    actions
  end

  filter :email
  filter :phone_number
  filter :created_at
  filter :updated_at
  filter :group

  form do |f|
    f.inputs do
      f.input :email
      f.input :phone_number
      if f.object.group.present?
        f.input :group, as: :select, collection: Group.all, include_blank: "Select Group"
        span "This user is already assigned to the group #{f.object.group.name}", class: "help-block"
      else
        f.input :group, as: :select, collection: Group.all, include_blank: "Select Group"
      end
      # f.input :group, as: :select, collection: Group.all.collect { |g| [ g.name, g.id ] }, include_blank: true
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:group).order("groups.name DESC") # Sort by group name
    end
  end
end
