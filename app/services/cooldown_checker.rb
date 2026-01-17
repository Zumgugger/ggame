# app/services/cooldown_checker.rb
class CooldownChecker
  def initialize(group, option, target_group = nil)
    @group = group
    @option = option
    @target_group = target_group
  end

  # Check if action is allowed based on cooldown
  # Returns { allowed: true/false, reason: "message" }
  def check
    option_setting = @option.option_setting
    return { allowed: true } unless option_setting&.cooldown_seconds&.> 0

    case @option.name
    when "hat Gruppe fotografiert"
      check_foto_cooldown(option_setting)
    when "hat spioniert"
      check_spionage_cooldown(option_setting)
    when "hat Foto bemerkt"
      check_foto_noticed_cooldown(option_setting)
    else
      { allowed: true }
    end
  end

  private

  # "hat Gruppe fotografiert" - 60 min cooldown pro Zielgruppe
  def check_foto_cooldown(option_setting)
    return { allowed: false, reason: "Zielgruppe erforderlich" } unless @target_group

    last_event = Event
      .where(option: @option, group: @group, target_group: @target_group)
      .order(:time)
      .last

    if last_event
      time_since = Time.now - last_event.time
      if time_since < option_setting.cooldown_seconds
        minutes_left = ((option_setting.cooldown_seconds - time_since) / 60).ceil
        { 
          allowed: false, 
          reason: "Cooldown aktiv. Versuche es in #{minutes_left} Minute(n) erneut."
        }
      else
        { allowed: true }
      end
    else
      { allowed: true }
    end
  end

  # "hat spioniert" - 60 min cooldown pro Zielgruppe
  def check_spionage_cooldown(option_setting)
    return { allowed: false, reason: "Zielgruppe erforderlich" } unless @target_group

    last_event = Event
      .where(option: @option, group: @group, target_group: @target_group)
      .order(:time)
      .last

    if last_event
      time_since = Time.now - last_event.time
      if time_since < option_setting.cooldown_seconds
        minutes_left = ((option_setting.cooldown_seconds - time_since) / 60).ceil
        { 
          allowed: false, 
          reason: "Cooldown aktiv. Versuche es in #{minutes_left} Minute(n) erneut."
        }
      else
        { allowed: true }
      end
    else
      { allowed: true }
    end
  end

  # "hat Foto bemerkt" - 10 min window pro Zielgruppe
  def check_foto_noticed_cooldown(option_setting)
    return { allowed: false, reason: "Zielgruppe erforderlich" } unless @target_group

    last_foto_noticed = Event
      .where(option: @option, group: @group, target_group: @target_group)
      .order(:time)
      .last

    if last_foto_noticed
      time_since = Time.now - last_foto_noticed.time
      if time_since < option_setting.cooldown_seconds
        seconds_left = (option_setting.cooldown_seconds - time_since).ceil
        { 
          allowed: false, 
          reason: "Foto wurde schon bemerkt. Warte #{seconds_left} Sekunden."
        }
      else
        { allowed: true }
      end
    else
      { allowed: true }
    end
  end
end
