# == Schema Information
#
# Table name: targets
#
#  id          :bigint           not null, primary key
#  count       :integer          default(0)
#  description :string
#  last_action :datetime
#  mines       :integer          default(0)
#  name        :string
#  points      :integer          default(100)
#  sort_order  :integer
#  village     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Target < ApplicationRecord
  has_many :events
  has_many :submissions
  require "csv"

  # Define searchable attributes for Ransack
  def self.ransackable_attributes(auth_object = nil)
    [ "id", "name", "description", "points", "mines", "count", "last_action", "village", "sort_order", "created_at", "updated_at" ]
  end

  # Define searchable associations for Ransack
  def self.ransackable_associations(auth_object = nil)
    [ "events" ]
  end

  def self.import_from_csv(file)
    # Assuming the file is a CSV, and you want to parse it
    Rails.logger.debug("Importing file: #{file.inspect}")

    # Open and process the CSV file
    CSV.foreach(file.path, headers: true) do |row|
      # Process each row here, e.g., create new Target records
      target = Target.new(row.to_hash)
      if target.save
        Rails.logger.debug("Target imported: #{target.inspect}")
      else
        Rails.logger.error("Error importing target: #{target.errors.full_messages}")
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error reading CSV file: #{e.message}")
    raise e
  end
end
