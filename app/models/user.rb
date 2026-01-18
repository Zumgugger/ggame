# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  name                   :string
#  phone_number           :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  belongs_to :group, optional: true
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable
         validates :email, uniqueness: true, allow_blank: true

  # Define searchable attributes for Ransack
  def self.ransackable_attributes(auth_object = nil)
    # List the attributes you want to be searchable
    [ "id", "name", "email", "phone_number", "created_at", "updated_at", "remember_created_at", "reset_password_sent_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "group" ]
  end
end
