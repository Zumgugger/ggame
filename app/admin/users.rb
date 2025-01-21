ActiveAdmin.register User do
  permit_params do
    permitted = [ :group_id, :email, :phone_number, :name ]
    permitted += [ :password, :password_confirmation ] if params[:action] == "create"
    permitted
  end

  index do
    selectable_column
    id_column
    column :group, sortable: "groups.name" do |user|
      user.group&.name || "No Group"
    end
    column :name
    column :email
    column :phone_number
    column :created_at
    column :updated_at
    column :sign_in_count

    actions
  end

  filter :name
  filter :email
  filter :phone_number
  filter :created_at
  filter :updated_at
  filter :group

  form do |f|
    f.inputs do
      f.input :name
      f.input :email
      f.input :phone_number
      f.input :group, as: :select, collection: Group.all, include_blank: "Select Group"
      if f.object.new_record?
        f.input :password, input_html: { value: "test123" }
        f.input :password_confirmation, input_html: { value: "test123" }
      else
        f.input :password
        f.input :password_confirmation
      end
      if f.object.persisted? && f.object.group.present?
        span "This user is already assigned to the group #{f.object.group.name}", class: "help-block"
      end
    end
    f.actions
  end

  controller do
    def scoped_collection
      super.includes(:group).order("groups.name DESC") # Sort by group name
    end

    def create
      @user = User.new(permitted_params[:user])
      if @user.save
        redirect_to admin_user_path(@user), notice: "User successfully created."
      else
        Rails.logger.error(@user.errors.full_messages.to_sentence)
        flash[:error] = @user.errors.full_messages.to_sentence
        render :new
      end
    end
  end
end
