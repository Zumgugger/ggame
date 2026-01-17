ActiveAdmin.register_page "Regeln Editor" do
  menu label: "📜 Regeln bearbeiten", priority: 10

  content do
    @option_settings = OptionSetting.includes(:option).all

    div class: "rules-editor" do
      h2 "Spielregeln bearbeiten", style: "margin-bottom: 20px;"
      
      para style: "color: #666; margin-bottom: 20px;" do
        "Hier können Sie die Regeltexte für alle Optionen bearbeiten. Die Änderungen werden automatisch auf der Spieler-Regelseite angezeigt."
      end

      # Preview link
      div style: "margin-bottom: 30px;" do
        link_to "👁️ Regeln-Vorschau öffnen", "/play/rules", target: "_blank", class: "button"
      end

      @option_settings.each do |setting|
        panel setting.option.name, class: "rule-panel" do
          div style: "display: flex; gap: 20px; align-items: flex-start;" do
            # Current rule text
            div style: "flex: 2;" do
              active_admin_form_for [:admin, setting], url: admin_option_setting_path(setting), method: :patch do |f|
                f.inputs do
                  f.input :rule_text, label: false, as: :text, input_html: { 
                    rows: 4, 
                    style: "width: 100%; font-size: 14px;",
                    placeholder: "Regeltext eingeben..."
                  }
                  f.input :available_to_players, label: "Für Spieler sichtbar"
                end
                f.actions do
                  f.action :submit, label: "💾 Speichern", button_html: { style: "background-color: #5cb85c;" }
                end
              end
            end
            
            # Info sidebar
            div style: "flex: 1; background: #f5f5f5; padding: 15px; border-radius: 5px; font-size: 13px;" do
              h4 "Einstellungen", style: "margin-top: 0; margin-bottom: 10px; font-size: 14px;"
              para do
                strong "Punkte: "
                span setting.points.to_s
              end if setting.points.to_i > 0
              para do
                strong "Kosten: "
                span "#{setting.cost} Punkte"
              end if setting.cost.to_i > 0
              para do
                strong "Cooldown: "
                span "#{setting.cooldown_minutes} Min"
              end if setting.cooldown_seconds.to_i > 0
              para do
                strong "Foto: "
                span setting.requires_photo ? "Erforderlich" : "Nicht erforderlich"
              end
              hr
              para style: "color: #888; font-style: italic; margin-top: 10px;" do
                strong "Standard: "
                span setting.rule_text_default.presence || "Kein Standard"
              end
              if setting.rule_text != setting.rule_text_default
                div style: "margin-top: 10px;" do
                  link_to "↩️ Auf Standard zurücksetzen", reset_rule_admin_option_setting_path(setting),
                          method: :post,
                          data: { confirm: "Regeltext auf Standardwert zurücksetzen?" },
                          style: "color: #d9534f; font-size: 12px;"
                end
              end
            end
          end
        end
      end
    end

    # Add some custom CSS
    style do
      raw <<-CSS
        .rules-editor .panel {
          margin-bottom: 20px;
        }
        .rules-editor .panel h3 {
          background: #4CAF50;
          color: white;
          padding: 10px 15px;
          margin: 0;
          font-size: 16px;
        }
        .rules-editor textarea {
          border: 1px solid #ddd;
          border-radius: 4px;
          padding: 10px;
        }
        .rules-editor textarea:focus {
          border-color: #4CAF50;
          outline: none;
          box-shadow: 0 0 5px rgba(76, 175, 80, 0.3);
        }
        .rules-editor .actions {
          margin-top: 10px;
          padding: 0;
        }
        .rules-editor .button {
          background: #5cb85c;
          color: white;
          border: none;
          padding: 8px 15px;
          border-radius: 4px;
          cursor: pointer;
        }
        .rules-editor .button:hover {
          background: #4cae4c;
        }
      CSS
    end
  end
end
