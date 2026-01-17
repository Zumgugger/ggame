# db/seeds/option_settings_defaults.rb
# Default settings for each game option

OPTION_DEFAULTS = {
  "hat Posten geholt" => {
    requires_photo: true,
    requires_target: true,
    auto_verify: false,
    points: 0,
    cost: 0,
    cooldown_seconds: 0,
    rule_text: "Jeder Posten kann nur einmal geholt werden. Bonus für ersten Abruf.",
    available_to_players: true
  },
  "hat Mine gesetzt" => {
    requires_photo: false,
    requires_target: true,
    auto_verify: true,
    points: 0,
    cost: 0, # Variable - user sets during action
    cooldown_seconds: 0,
    rule_text: "Kosten: Beliebig viele Punkte. Mine hat doppelten Wert.",
    available_to_players: true
  },
  "hat Gruppe fotografiert" => {
    requires_photo: true,
    requires_target: false,
    auto_verify: false,
    points: 400,
    cost: 0,
    cooldown_seconds: 3600, # 60 minutes per target group
    rule_text: "Du kannst jede Gruppe fotografieren (60 Min Cooldown pro Gruppe). Gegnerische Gruppe kann 60 Min lang nicht zurückfotografieren.",
    available_to_players: true
  },
  "hat sondiert" => {
    requires_photo: false,
    requires_target: true,
    auto_verify: true,
    points: 0,
    cost: 50,
    cooldown_seconds: 0,
    rule_text: "Zeigt, ob ein Posten vermint ist. Kosten: 50 Punkte.",
    available_to_players: true
  },
  "hat spioniert" => {
    requires_photo: false,
    requires_target: false,
    auto_verify: true,
    points: 0,
    cost: 50,
    cooldown_seconds: 3600, # 60 minutes per target group
    rule_text: "Zeigt Punktestand einer Gruppe (60 Min Cooldown pro Zielgruppe). Kosten: 50 Punkte.",
    available_to_players: true
  },
  "hat Foto bemerkt" => {
    requires_photo: false,
    requires_target: false,
    auto_verify: true,
    points: 200,
    cost: 0,
    cooldown_seconds: 600, # 10 minutes window
    rule_text: "Melde innerhalb 10 Min, dass du fotografiert wurdest (pro Gruppe).",
    available_to_players: true
  },
  "Spionageabwehr" => {
    requires_photo: false,
    requires_target: false,
    auto_verify: true,
    points: 0,
    cost: 300,
    cooldown_seconds: 0,
    rule_text: "Gegner erhalten Falschinformationen bei Spionage. Kosten: 300 Punkte.",
    available_to_players: true
  },
  "hat Kopfgeld gesetzt" => {
    requires_photo: false,
    requires_target: false,
    auto_verify: true,
    points: 0,
    cost: 0, # Variable - user sets during action
    cooldown_seconds: 0,
    rule_text: "Setze Kopfgeld auf eine Gruppe. Kosten: Beliebig viele Punkte.",
    available_to_players: true
  },
  "hat Mine entschärft" => {
    requires_photo: false,
    requires_target: true,
    auto_verify: true,
    points: 0,
    cost: 50,
    cooldown_seconds: 0,
    rule_text: "Entschärft alle Minen eines Postens. Kosten: 50 Punkte.",
    available_to_players: true
  }
}.freeze
