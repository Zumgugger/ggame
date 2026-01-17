ActiveAdmin.register OptionSetting do
  menu label: "Optionen-Einstellungen", priority: 2

  permit_params :requires_photo, :requires_target, :auto_verify, :points, :cost, 
                :cooldown_seconds, :rule_text, :available_to_players

  index do
    selectable_column
    column "Option" do |setting|
      setting.option.name
    end
    column "Foto nötig?" do |setting|
      setting.requires_photo ? "✓ Ja" : "✗ Nein"
    end
    column "Ziel nötig?" do |setting|
      setting.requires_target ? "✓ Ja" : "✗ Nein"
    end
    column "Auto-Verify" do |setting|
      setting.auto_verify ? "✓ Ja" : "✗ Nein"
    end
    column "Punkte", :points
    column "Kosten", :cost
    column "Cooldown" do |setting|
      "#{setting.cooldown_minutes} Min"
    end
    column "Verfügbar" do |setting|
      setting.available_to_players ? "✓ Ja" : "✗ Nein"
    end
    actions
  end

  filter :option
  filter :requires_photo
  filter :auto_verify
  filter :available_to_players

  form do |f|
    f.semantic_errors
    
    f.inputs "Option" do
      f.input :option, input_html: { disabled: true }, hint: "Option kann nicht geändert werden"
    end

    f.inputs "Verhalten" do
      f.input :requires_photo, label: "Foto erforderlich?", hint: "Muss der Spieler ein Foto hochladen?"
      f.input :requires_target, label: "Ziel (Posten) erforderlich?", hint: "Muss ein Posten ausgewählt werden?"
      f.input :auto_verify, label: "Automatisch verifizieren?", hint: "Wenn nein, muss Admin manuell bestätigen"
      f.input :available_to_players, label: "Für Spieler verfügbar?", hint: "In der Spieler-App anzeigen?"
    end

    f.inputs "Punkte & Kosten" do
      f.input :points, label: "Punkte", hint: "Punkte, die bei Ausführung vergeben werden"
      f.input :cost, label: "Kosten", hint: "Punkte, die bei Ausführung abgezogen werden (0 = kostenlos)"
      f.input :cooldown_seconds, label: "Cooldown (Sekunden)", hint: "Wartezeit zwischen Aktionen (pro Zielgruppe)"
    end

    f.inputs "Regeltext" do
      f.input :rule_text, label: "Regel", as: :text, input_html: { rows: 3 }, 
              hint: "Beschreibung der Regel für Spieler"
    end

    f.actions do
      f.action :submit, label: "Speichern"
      f.cancel_link
    end
  end

  show do
    attributes_table do
      row "Option" do |setting|
        link_to setting.option.name, admin_option_path(setting.option)
      end
      row "Foto erforderlich?" do |setting|
        setting.requires_photo ? "✓ Ja" : "✗ Nein"
      end
      row "Ziel erforderlich?" do |setting|
        setting.requires_target ? "✓ Ja" : "✗ Nein"
      end
      row "Auto-Verify" do |setting|
        setting.auto_verify ? "✓ Ja" : "✗ Nein"
      end
      row "Für Spieler verfügbar?" do |setting|
        setting.available_to_players ? "✓ Ja" : "✗ Nein"
      end
      row :points
      row :cost
      row "Cooldown" do |setting|
        "#{setting.cooldown_minutes} Minuten (#{setting.cooldown_seconds} Sekunden)"
      end
      row :rule_text
      row :rule_text_default
    end

    panel "Aktionen" do
      div style: "margin: 20px 0;" do
        link_to "Regel auf Standard zurücksetzen", reset_rule_admin_option_setting_path(resource),
                method: :post,
                data: { confirm: "Regeltext auf Standardwert zurücksetzen?" },
                class: "button"
        
        span style: "margin-left: 10px;" do
          link_to "Aktuelle Regel als Standard speichern", save_rule_admin_option_setting_path(resource),
                  method: :post,
                  data: { confirm: "Aktuellen Regeltext als neuen Standard speichern?" },
                  class: "button"
        end
      end
    end
  end

  member_action :reset_rule, method: :post do
    resource.reset_rule_to_default!
    redirect_to admin_option_setting_path(resource), notice: "Regel auf Standard zurückgesetzt!"
  end

  member_action :save_rule, method: :post do
    resource.save_rule_as_default!
    redirect_to admin_option_setting_path(resource), notice: "Regel als Standard gespeichert!"
  end
end
