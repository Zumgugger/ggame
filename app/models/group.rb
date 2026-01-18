# == Schema Information
#
# Table name: groups
#
#  id                :bigint           not null, primary key
#  false_information :boolean
#  join_token        :string           not null
#  kopfgeld          :integer
#  name              :string
#  name_editable     :boolean          default(TRUE)
#  points            :integer          default(0)
#  sort_order        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_groups_on_join_token  (join_token) UNIQUE
#
class Group < ApplicationRecord
  has_many :events
  has_many :player_sessions
  has_many :submissions
  
  # Events where this group is the target (being photographed, etc.)
  has_many :targeted_events, class_name: 'Event', foreign_key: 'target_group_id'

  # Store QR code image
  has_one_attached :qr_code

  # Generate join token before validation
  before_validation :generate_join_token, on: :create
  
  # Generate QR code image after creation
  after_create :generate_qr_code_image
  
  # Delete QR code image when group is destroyed
  before_destroy :delete_qr_code_image

  validates :join_token, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "false_information", "id", "kopfgeld", "name", "name_editable", "points", "sort_order", "updated_at", "join_token" ]
  end
  def self.ransackable_associations(auth_object = nil)
    [ "events" ]
  end

  # Generate QR code for joining
  def qr_code_url
    base_url = ENV.fetch('APP_URL', 'http://localhost:3000')
    "#{base_url}/join/#{join_token}"
  end

  # Points visible to players - hides recent photo deductions until window expires
  # This prevents groups from knowing they were photographed by watching their points
  def player_visible_points
    # Find events where this group is the target and the deduction is still hidden
    hidden_deductions = targeted_events
      .where('hidden_until > ?', Time.current)
      .where.not(target_points: nil)
      .sum(:target_points)
    
    # Add back the hidden deductions (they're negative, so this shows higher points)
    points - hidden_deductions
  end

  # Ensure QR code exists (for existing groups or if it was deleted)
  def ensure_qr_code!
    return if qr_code.attached?
    generate_qr_code_image
  end

  private

  def generate_join_token
    self.join_token ||= SecureRandom.urlsafe_base64(12)
  end

  def generate_qr_code_image
    # Generate QR code from join URL
    # Use direct URL construction since we're in a model without full request context
    base_url = ENV.fetch('APP_URL', 'http://localhost:3000')
    qr_url = "#{base_url}/join/#{join_token}"
    qr = RQRCode::QRCode.new(qr_url, size: 10, level: :h)
    
    # Convert to PNG image
    qr_png = qr.as_png(size: 300)
    
    # Attach to the group using StringIO
    qr_code.attach(io: StringIO.new(qr_png.to_s), filename: "qrcode_#{join_token}.png", content_type: "image/png")
  end

  def delete_qr_code_image
    qr_code.purge if qr_code.attached?
  end
end
