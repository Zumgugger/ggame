# == Schema Information
#
# Table name: events
#
#  id                  :bigint           not null, primary key
#  description         :string
#  group_points        :integer
#  noticed             :boolean
#  points_set          :integer
#  target_group_points :integer
#  target_points       :integer
#  time                :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  group_id            :integer
#  option_id           :integer
#  target_group_id     :integer
#  target_id           :integer
#
class Event < ApplicationRecord
  belongs_to :group
  belongs_to :option, optional: false
  belongs_to :target_group, class_name: "Group", optional: true
  belongs_to :target, optional: true

  # Nested Attributes
  accepts_nested_attributes_for :target, :group

  def group_name
    group&.name || "-"
  end

  def option_name
    option&.name || "-"
  end

  def target_name
    target&.name || "-"
  end

  def event_description
    event&.description || "-"
  end

  def append_to_description(text)
    self.description = [ self.description, text ].compact.join(", ")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "id", "created_at", "updated_at", "description", "group_id", "group_points", "noticed", "option_id", "points_set", "target_id", "target_points", "time" ]
  end

  # Define searchable associations for Ransack (if needed)
  def self.ransackable_associations(auth_object = nil)
    [] # If no associations are needed for search, leave it empty
  end

  def calculate_points
    self.time = Time.now
    self.group_points = 0
    group = Group.find(group_id)
    target = Target.find(target_id) if target_id
    target_group = Group.find(target_group_id) if target_group_id

    case option.name
    when "hat Posten geholt"
      @last_time = Event.where(option: option, group: group, target: target).last
      if @last_time
        self.group_points = 0
        self.description = "schon geholt"
      else
        self.group_points = target.points - target.mines
        self.group_points += 100 if target.count == 0
        append_to_description("Bonus geholt") if target.count == 0
        append_to_description("Boom! #{target.mines}") if target.mines != 0
        target.mines = 0
        target.count += 1
      end
    when "hat Mine gesetzt"
      if group.points < points_set
        append_to_description("zu teuer")
        self.group_points = 0
      else
        self.group_points = -points_set
        target.mines += 2 * points_set
      end
    when "hat Gruppe fotografiert"
      @last_foto_made = Event.where(option: option, target_group: target_group, group: group).where.not(group_points: 0).last
      @last_foto_got = Event.where(option: option, target_group: group, group: target_group).where.not(group_points: 0).last
      @time_last_foto_got = @time_last_foto_made = Time.now - 100.minutes # set the default somewhere in the distant past
      if @last_foto_made
        @time_last_foto_made = @last_foto_made.time
      end
      if @last_foto_got
        @time_last_foto_got = @last_foto_got.time
      end
      error_triggered = false
      if group == target_group
        append_to_description("eigene Gruppe")
        self.group_points = 0
        self.target_points = 0
        error_triggered = true
      end
      if @time_last_foto_made + 60.minutes > Time.now
        append_to_description(" zu früh wieder fotografiert ")
        self.group_points = 0
        self.target_points = 0
        error_triggered = true
      end
      if @time_last_foto_got + 60.minutes > Time.now
        append_to_description("zu früh zurückfotografiert ")
        self.group_points = 0
        self.target_points = 0
        error_triggered = true
      end
      unless error_triggered
        self.group_points = 400
        if target_group.kopfgeld != 0
          self.group_points += target_group.kopfgeld
          target_group.kopfgeld = 0
          append_to_description("Kopfgeld geholt")
        end
        self.target_points = -400
        target_group.points += self.target_points
      end
    when "hat sondiert"
      if group.points < 50
        self.description = "zu teuer"
        self.group_points = 0
      else
        self.group_points = -50
        self.description = "Mine vorhanden" if target.mines != 0
      end
    when "hat spioniert"
      @last_spionage_event = Event.where(option: option, target_group: target_group, group: group).last
      @time = Time.now - 60.minutes
      if @last_spionage_event
        @time = @last_spionage_event.time
      end
      if group.points < 50
        self.description = "zu teuer"
        self.group_points = 0
      elsif group == target_group
        self.description = "eigene Gruppe"
        self.group_points = 0
      elsif @time + 60.minutes > Time.now
        self.description = "zu früh"
        self.group_points = 0
      elsif target_group.false_information == true
        self.description = "Falschinformation!"
        self.group_points = -50
        target_group.false_information = false
      else
        self.group_points = -50
        self.description = "Spionage!"
      end
    when "Spionageabwehr"
      if group.points < 300
        self.description = "zu teuer"
        self.group_points = 0
      elsif group.false_information == true
        self.description = "bereits vorhanden"
        self.group_points = 0
      else
        self.group_points = -300
        group.false_information = true
      end
    when "hat Foto bemerkt" # fix this.
      @option = Option.where(name: "hat Gruppe fotografiert")
      @last_foto_event = Event.where(option: @option, target_group: target_group, group: group).last
      @time = Time.now - 60.minutes
      if @last_foto_event
        @time = @last_foto_event.time
      end
      if group == target_group
        self.description = "eigene Gruppe"
        self.group_points = 0
        self.target_points = 0
      elsif Time.now <= @time + 10.minutes
        self.description = "zu spät bzw. falsche Gruppe"
        self.group_points = 0
        self.target_points = 0
      else
        self.group_points = 200
        self.target_points = -200
        target_group.points += self.target_points
      end
    when "hat Kopfgeld gesetzt"
      if group.points < points_set
        self.description = "zu teuer"
        self.group_points = 0
      else
        self.group_points = -points_set
        target_group.kopfgeld += points_set
      end
    when "hat Mine entschärft"
      if group.points < 50
        self.description = "zu teuer"
        self.group_points = 0
      else
        self.group_points = -50
        target.mines = 0
      end
    end
    group.points += self.group_points
    target.last_action = Time.now if target
    group.save if group
    target.save if target
    target_group.save if target_group
  end
end
