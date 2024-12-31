module Ggame
  class UploadsController < ApplicationController
    before_action :authenticate_admin_user!
    def index
      @uploads = [] # Ensure @uploads is initialized as an empty array
    end

    def create
      if params[:file].present?
        Rails.logger.debug("File received: #{params[:file].inspect}")
        begin
          Target.import_from_csv(params[:file])
          redirect_to ggame_uploads_path, notice: "File uploaded and processed successfully!"
        rescue StandardError => e
          Rails.logger.error("Error processing file: #{e.message}")
          redirect_to ggame_uploads_path, alert: "Error processing file: #{e.message}"
        end
      else
        redirect_to ggame_uploads_path, alert: "Please select a file to upload."
      end
    end
  end
end
