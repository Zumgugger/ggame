ActiveAdmin.register GameSetting do
  menu label: "Spieleinstellungen", priority: 1

  # Only allow editing the singleton instance
  actions :all, except: [:destroy, :new, :create]

  permit_params :point_multiplier, :game_active, :game_start_time, :game_end_time,
                game_time_windows_attributes: [:id, :name, :start_time, :end_time, :position, :_destroy]

  controller do
    def index
      redirect_to admin_game_setting_path(GameSetting.instance)
    end
  end

  form do |f|
    f.semantic_errors
    
    f.inputs "Spielzeiten (Legacy - wird ignoriert wenn Zeitfenster definiert sind)" do
      f.input :game_active, label: "Spiel aktiv", hint: "Manuelle Aktivierung (überschreibt Zeitfenster)"
      f.input :game_start_time, label: "Startdatum", as: :date_picker
      f.input :game_start_time, label: "Startzeit (HH:MM)", as: :time_picker, input_html: { type: 'time' }
      f.input :game_end_time, label: "Enddatum", as: :date_picker
      f.input :game_end_time, label: "Endzeit (HH:MM)", as: :time_picker, input_html: { type: 'time' }
    end

    f.inputs "Zeitfenster (mehrere möglich)" do
      f.has_many :game_time_windows, allow_destroy: true, new_record: true, heading: false do |w|
        w.input :name, label: "Name (z.B. 'Morgen Tag 1', 'Nachmittag Tag 1')", 
                hint: "Optional: Beschreibung des Zeitfensters"
        w.input :start_time, label: "Startdatum", as: :date_picker
        w.input :start_time, label: "Startzeit (HH:MM)", as: :time_picker, input_html: { type: 'time' }
        w.input :end_time, label: "Enddatum", as: :date_picker
        w.input :end_time, label: "Endzeit (HH:MM)", as: :time_picker, input_html: { type: 'time' }
        w.input :position, label: "Reihenfolge", hint: "Niedrigere Zahlen = früher"
      end
    end

    f.inputs "Punkteberechnung" do
      f.input :point_multiplier, label: "Punktemultiplikator", hint: "Alle Posten-Punkte werden mit diesem Faktor multipliziert (z.B. 1.5 für 1.5x Punkte)"
    end

    f.actions do
      f.action :submit, label: "Speichern"
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row :game_active do |settings|
        settings.game_active ? "✓ Aktiv" : "✗ Inaktiv"
      end
      row :point_multiplier
      row "Spiel läuft?" do |settings|
        settings.game_running? ? "✓ Ja" : "✗ Nein"
      end
    end

    panel "Zeitfenster" do
      if resource.game_time_windows.any?
        table_for resource.game_time_windows.ordered do
          column "Name", :name
          column "Start" do |window|
            window.start_time.strftime("%d.%m.%Y %H:%M")
          end
          column "Ende" do |window|
            window.end_time.strftime("%d.%m.%Y %H:%M")
          end
          column "Dauer" do |window|
            "#{window.duration_hours}h"
          end
          column "Aktuell aktiv?" do |window|
            window.active? ? "✓ Ja" : "✗ Nein"
          end
        end
      else
        div do
          strong "Keine Zeitfenster definiert"
          br
          span "Fallback: Einfache Start/Endzeit wird verwendet"
          br
          span "Start: #{resource.game_start_time&.strftime("%d.%m.%Y %H:%M") || "Nicht gesetzt"}"
          br
          span "Ende: #{resource.game_end_time&.strftime("%d.%m.%Y %H:%M") || "Nicht gesetzt"}"
        end
      end
    end

    panel "Aktionen" do
      div style: "margin: 20px 0;" do
        if resource.game_active
          link_to "Spiel stoppen", stop_admin_game_setting_path(resource), 
                  method: :post, 
                  data: { confirm: "Spiel wirklich stoppen?" },
                  class: "button"
        else
          link_to "Spiel starten", start_admin_game_setting_path(resource), 
                  method: :post,
                  data: { confirm: "Spiel wirklich starten?" },
                  class: "button"
        end
        
        span style: "margin: 0 10px;" do
          link_to "Auf Standard zurücksetzen", reset_admin_game_setting_path(resource),
                  method: :post,
                  data: { confirm: "Alle Einstellungen auf Standardwerte zurücksetzen?" },
                  class: "button"
        end

        span do
          link_to "Aktuelle Werte als Standard speichern", save_defaults_admin_game_setting_path(resource),
                  method: :post,
                  data: { confirm: "Aktuelle Einstellungen als neue Standardwerte speichern?" },
                  class: "button"
        end
      end
    end
  end

  member_action :start, method: :post do
    resource.start_game!
    redirect_to admin_game_setting_path(resource), notice: "Spiel gestartet!"
  end

  member_action :stop, method: :post do
    resource.stop_game!
    redirect_to admin_game_setting_path(resource), notice: "Spiel gestoppt!"
  end

  member_action :reset, method: :post do
    resource.reset_to_defaults!
    redirect_to admin_game_setting_path(resource), notice: "Einstellungen auf Standard zurückgesetzt!"
  end

  member_action :save_defaults, method: :post do
    resource.save_as_defaults!
    redirect_to admin_game_setting_path(resource), notice: "Aktuelle Werte als Standard gespeichert!"
  end
end
