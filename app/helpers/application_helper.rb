module ApplicationHelper
  def admin_avatar_letter
    if current_admin_user.present?
      current_admin_user.email[0].upcase
    else
      'G'
    end
  end
end
