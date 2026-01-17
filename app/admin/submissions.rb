ActiveAdmin.register Submission do
  menu priority: 3, label: "Einreichungen"
  
  # Permit parameters
  permit_params :status, :admin_message

  # Disable all batch actions to avoid issues
  config.batch_actions = false

  # Filters
  filter :group
  filter :option
  filter :status, as: :select, collection: Submission::STATUSES
  filter :submitted_at
  filter :player_session_player_name, as: :string, label: 'Spielername'

  # Scopes for quick filtering
  scope :all
  scope :pending, default: true
  scope :processable, label: "Bereit"
  scope :queued, label: "In Warteschlange"
  scope :verified
  scope :denied

  # Custom actions for verify/deny
  member_action :verify, method: :post do
    submission = Submission.find(params[:id])
    message = params[:admin_message]
    
    if submission.verify!(current_admin_user, message: message)
      redirect_to admin_submissions_path, notice: "Einreichung bestätigt! Event erstellt."
    else
      redirect_to admin_submissions_path, alert: "Fehler: #{submission.errors.full_messages.join(', ')}"
    end
  end

  member_action :deny, method: :post do
    submission = Submission.find(params[:id])
    message = params[:admin_message].presence || 'Abgelehnt'
    
    if submission.deny!(current_admin_user, message: message)
      redirect_to admin_submissions_path, notice: "Einreichung abgelehnt."
    else
      redirect_to admin_submissions_path, alert: "Fehler beim Ablehnen."
    end
  end

  # Photo management actions
  member_action :download_photo, method: :get do
    submission = Submission.find(params[:id])
    if submission.photo.attached?
      # Generate a descriptive filename
      filename = submission.photo_filename
      redirect_to rails_blob_path(submission.photo, disposition: :attachment, filename: filename), allow_other_host: true
    else
      redirect_to admin_submission_path(submission), alert: "Kein Foto vorhanden."
    end
  end

  member_action :delete_photo, method: :delete do
    submission = Submission.find(params[:id])
    if submission.photo.attached?
      submission.photo.purge
      redirect_to admin_submission_path(submission), notice: "Foto gelöscht."
    else
      redirect_to admin_submission_path(submission), alert: "Kein Foto vorhanden."
    end
  end

  member_action :archive_photo, method: :post do
    submission = Submission.find(params[:id])
    if submission.photo.attached?
      # This action triggers download and then deletes
      # We use a special flow: redirect to download, then JS will call delete
      filename = submission.photo_filename
      redirect_to rails_blob_path(submission.photo, disposition: :attachment, filename: filename), allow_other_host: true
      # Note: Photo deletion happens via separate delete_photo call after download
    else
      redirect_to admin_submission_path(submission), alert: "Kein Foto vorhanden."
    end
  end

  # Bulk photo actions
  collection_action :download_all_photos, method: :get do
    submissions = Submission.where(id: params[:submission_ids]).includes(photo_attachment: :blob)
    photos_to_download = submissions.select { |s| s.photo.attached? }
    
    if photos_to_download.empty?
      redirect_to admin_submissions_path, alert: "Keine Fotos zum Herunterladen."
      return
    end

    # Create a zip file with all photos
    require 'zip'
    
    temp_file = Tempfile.new(['photos', '.zip'])
    begin
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
        photos_to_download.each do |submission|
          filename = submission.photo_filename
          zipfile.get_output_stream(filename) do |f|
            f.write(submission.photo.download)
          end
        end
      end
      
      send_file temp_file.path,
                filename: "fotos_#{Time.current.strftime('%Y%m%d_%H%M%S')}.zip",
                type: 'application/zip',
                disposition: 'attachment'
    ensure
      temp_file.close
    end
  end

  collection_action :delete_all_photos, method: :delete do
    submissions = Submission.where(id: params[:submission_ids])
    deleted_count = 0
    
    submissions.each do |submission|
      if submission.photo.attached?
        submission.photo.purge
        deleted_count += 1
      end
    end
    
    redirect_to admin_submissions_path, notice: "#{deleted_count} Fotos gelöscht."
  end

  # Index view - verification queue
  index do
    id_column
    
    column :status do |submission|
      case submission.status
      when 'pending'
        if submission.queued?
          status_tag '⏳ Warteschlange', class: 'warning'
        else
          status_tag 'Ausstehend', class: 'warning'
        end
      when 'verified'
        status_tag 'Bestätigt', class: 'yes'
      when 'denied'
        status_tag 'Abgelehnt', class: 'no'
      end
    end
    
    column "Warteschlange" do |submission|
      if submission.queued?
        span style: 'color: #f0ad4e; font-size: 12px;' do
          "⏳ #{submission.queue_reason}"
        end
      elsif submission.queued_submissions.pending.any?
        span style: 'color: #5bc0de; font-size: 12px;' do
          "🔒 Blockiert #{submission.queued_submissions.pending.count} andere"
        end
      else
        '-'
      end
    end
    
    column :group
    column :option
    column "Posten", :target
    column "Zielgruppe", :target_group
    column "Punkte", :points_set do |submission|
      submission.points_set if submission.points_set.present?
    end
    
    column "Spieler", :player_session do |submission|
      submission.player_session&.player_name || '-'
    end
    
    column "Foto" do |submission|
      if submission.photo.attached?
        link_to '📷 Foto', rails_blob_path(submission.photo, disposition: :inline), target: '_blank'
      else
        '-'
      end
    end
    
    column "Wartezeit", :waiting_time do |submission|
      submission.waiting_time_text
    end
    
    column :submitted_at do |submission|
      submission.submitted_at.strftime('%H:%M:%S')
    end
    
    # Quick action buttons for pending submissions
    column "Aktionen" do |submission|
      if submission.status == 'pending'
        if submission.queued?
          span style: 'color: #f0ad4e;' do
            "Warten auf ##{submission.queued_behind_id}"
          end
        else
          span do
            button_to '✓ Bestätigen', verify_admin_submission_path(submission), 
                      method: :post, 
                      class: 'button small',
                      style: 'background-color: #5cb85c; border: none; margin-right: 5px;',
                      data: { confirm: 'Einreichung bestätigen?' }
          end
          span do
            button_to '✗ Ablehnen', deny_admin_submission_path(submission), 
                      method: :post, 
                      class: 'button small',
                      style: 'background-color: #d9534f; border: none;',
                      data: { confirm: 'Einreichung ablehnen?' }
          end
        end
      else
        submission.verified_by&.email || '-'
      end
    end
    
    actions
  end

  # Show view with photo display
  show do
    attributes_table do
      row :id
      row :status do |submission|
        case submission.status
        when 'pending'
          if submission.queued?
            status_tag '⏳ In Warteschlange', class: 'warning'
          else
            status_tag 'Ausstehend', class: 'warning'
          end
        when 'verified'
          status_tag 'Bestätigt', class: 'yes'
        when 'denied'
          status_tag 'Abgelehnt', class: 'no'
        end
      end
      if resource.queued?
        row "Warteschlange" do |submission|
          div style: 'color: #f0ad4e;' do
            "⏳ #{submission.queue_reason}"
          end
          div style: 'margin-top: 5px;' do
            link_to "→ Blockierende Einreichung ##{submission.queued_behind_id} anzeigen", 
                    admin_submission_path(submission.queued_behind_id)
          end
        end
      end
      if resource.queued_submissions.pending.any?
        row "Blockiert" do |submission|
          div style: 'color: #5bc0de;' do
            "🔒 Diese Einreichung blockiert #{submission.queued_submissions.pending.count} andere:"
          end
          ul do
            submission.queued_submissions.pending.each do |queued|
              li do
                link_to "##{queued.id}: #{queued.group.name} - #{queued.option.name}", 
                        admin_submission_path(queued)
              end
            end
          end
        end
      end
      row :group
      row :option
      row :target
      row :target_group
      row "Spieler" do |submission|
        submission.player_session&.player_name
      end
      row :description
      row :admin_message
      row :submitted_at
      row :verified_at
      row :verified_by
      row "Foto" do |submission|
        if submission.photo.attached?
          div do
            image_tag rails_blob_path(submission.photo, disposition: :inline), 
                      style: 'max-width: 100%; max-height: 500px; border-radius: 8px;'
          end
          div style: 'margin-top: 15px;' do
            span do
              link_to '📷 Foto öffnen', rails_blob_path(submission.photo, disposition: :inline), 
                      target: '_blank', class: 'button', style: 'margin-right: 10px;'
            end
            span do
              link_to '⬇️ Herunterladen', download_photo_admin_submission_path(submission), 
                      class: 'button', style: 'margin-right: 10px;'
            end
            span do
              link_to '🗑️ Löschen', delete_photo_admin_submission_path(submission),
                      method: :delete,
                      class: 'button',
                      style: 'background-color: #d9534f;',
                      data: { confirm: 'Foto wirklich löschen? Dies kann nicht rückgängig gemacht werden.' }
            end
          end
        else
          "Kein Foto"
        end
      end
    end

    # Action panel for pending submissions
    if resource.status == 'pending'
      panel "Aktion" do
        if resource.queued?
          div class: 'flash flash_alert', style: 'margin-bottom: 15px;' do
            "⚠️ Diese Einreichung ist in der Warteschlange. Sie sollte erst nach ##{resource.queued_behind_id} bearbeitet werden."
          end
        end
        div style: 'display: flex; gap: 20px; align-items: flex-start;' do
          div style: 'flex: 1;' do
            active_admin_form_for [:admin, resource], url: verify_admin_submission_path(resource), method: :post do |f|
              f.inputs 'Bestätigen' do
                f.input :admin_message, label: 'Nachricht (optional)', input_html: { rows: 2 }
              end
              f.actions do
                f.action :submit, label: '✓ Bestätigen', button_html: { style: 'background-color: #5cb85c;' }
              end
            end
          end
          
          div style: 'flex: 1;' do
            active_admin_form_for [:admin, resource], url: deny_admin_submission_path(resource), method: :post do |f|
              f.inputs 'Ablehnen' do
                f.input :admin_message, label: 'Begründung', input_html: { rows: 2 }
              end
              f.actions do
                f.action :submit, label: '✗ Ablehnen', button_html: { style: 'background-color: #d9534f;' }
              end
            end
          end
        end
      end
    end

    # Photo management panel for verified submissions with photos
    if resource.photo.attached?
      panel "Foto-Verwaltung" do
        div do
          span do
            link_to '⬇️ Foto herunterladen', download_photo_admin_submission_path(resource), 
                    class: 'button', style: 'background-color: #5cb85c; margin-right: 15px;'
          end
          span do
            link_to '🗑️ Foto löschen', delete_photo_admin_submission_path(resource),
                    method: :delete,
                    class: 'button',
                    style: 'background-color: #d9534f;',
                    data: { confirm: 'Foto wirklich löschen? Dies kann nicht rückgängig gemacht werden.' }
          end
        end
        para style: 'margin-top: 10px; color: #888; font-size: 12px;' do
          "Dateiname: #{resource.photo_filename}"
        end
      end
    end
    
    active_admin_comments
  end

  # Sidebar with statistics
  sidebar "Statistik", only: :index do
    div do
      h4 "Aktuelle Warteschlange"
      para "Ausstehend: #{Submission.pending.count}"
      para "→ Bereit: #{Submission.processable.count}"
      para "→ In Warteschlange: #{Submission.queued.count}"
      hr
      para "Heute bestätigt: #{Submission.verified.where('verified_at > ?', Date.today.beginning_of_day).count}"
      para "Heute abgelehnt: #{Submission.denied.where('verified_at > ?', Date.today.beginning_of_day).count}"
    end
  end

  # Sidebar with photo statistics
  sidebar "Fotos", only: :index do
    photos_count = Submission.joins(:photo_attachment).count
    verified_photos = Submission.verified.joins(:photo_attachment).count
    
    div do
      h4 "Foto-Übersicht"
      para "Gesamt mit Foto: #{photos_count}"
      para "Bestätigte mit Foto: #{verified_photos}"
      hr
      if verified_photos > 0
        para do
          link_to "⬇️ Alle bestätigten Fotos herunterladen", 
                  download_all_photos_admin_submissions_path(submission_ids: Submission.verified.joins(:photo_attachment).pluck(:id)),
                  class: 'button small',
                  style: 'background-color: #5cb85c;'
        end
        para style: 'margin-top: 10px;' do
          link_to "🗑️ Alle bestätigten Fotos löschen", 
                  delete_all_photos_admin_submissions_path(submission_ids: Submission.verified.joins(:photo_attachment).pluck(:id)),
                  method: :delete,
                  class: 'button small',
                  style: 'background-color: #d9534f;',
                  data: { confirm: "Wirklich alle #{verified_photos} Fotos löschen? Dies kann nicht rückgängig gemacht werden!" }
        end
      end
    end
  end

  # Controller customizations
  controller do
    def scoped_collection
      super.includes(:group, :option, :target, :target_group, :player_session, :verified_by, :queued_behind, :queued_submissions)
    end
  end
end
