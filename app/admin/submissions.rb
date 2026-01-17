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

  # Index view - verification queue
  index do
    id_column
    
    column :status do |submission|
      case submission.status
      when 'pending'
        status_tag 'Ausstehend', class: 'warning'
      when 'verified'
        status_tag 'Bestätigt', class: 'yes'
      when 'denied'
        status_tag 'Abgelehnt', class: 'no'
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
          status_tag 'Ausstehend', class: 'warning'
        when 'verified'
          status_tag 'Bestätigt', class: 'yes'
        when 'denied'
          status_tag 'Abgelehnt', class: 'no'
        end
      end
      row :group
      row :option
      row :target
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
          div style: 'margin-top: 10px;' do
            link_to 'Foto in neuem Tab öffnen', rails_blob_path(submission.photo, disposition: :inline), 
                    target: '_blank', class: 'button'
          end
        else
          "Kein Foto"
        end
      end
    end

    # Action panel for pending submissions
    if resource.status == 'pending'
      panel "Aktion" do
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
    
    active_admin_comments
  end

  # Sidebar with statistics
  sidebar "Statistik", only: :index do
    div do
      h4 "Aktuelle Warteschlange"
      para "Ausstehend: #{Submission.pending.count}"
      para "Heute bestätigt: #{Submission.verified.where('verified_at > ?', Date.today.beginning_of_day).count}"
      para "Heute abgelehnt: #{Submission.denied.where('verified_at > ?', Date.today.beginning_of_day).count}"
    end
  end

  # Controller customizations
  controller do
    def scoped_collection
      super.includes(:group, :option, :target, :target_group, :player_session, :verified_by)
    end
  end
end
