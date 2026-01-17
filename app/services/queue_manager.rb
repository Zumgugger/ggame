# QueueManager Service
# Manages the verification queue to ensure events are processed in correct time order.
#
# Why queuing is needed:
# If Group A submits "hat Gruppe B fotografiert" at 14:00 and it's pending verification,
# then Group B submits "hat Foto bemerkt" at 14:05, the "hat Foto bemerkt" MUST wait
# until the photo submission is verified (or denied), because:
# 1. If verified: "hat Foto bemerkt" should be valid (they noticed within 10 min)
# 2. If denied: "hat Foto bemerkt" should fail (no valid photo to notice)
#
# Queue scenarios:
# - "hat Foto bemerkt" waits for pending "hat Gruppe fotografiert" against same groups
# - "hat Gruppe fotografiert" waits for pending "hat Foto bemerkt" (time ordering)
# - Future: other time-dependent options

class QueueManager
  # Check if a new submission should be queued behind another
  # Returns { queued: false } or { queued: true, behind: Submission, reason: String }
  def self.check_queue(submission)
    new(submission).check
  end

  # Process queued submissions after one is verified/denied
  def self.process_queue_after(submission)
    new(submission).process_released
  end

  def initialize(submission)
    @submission = submission
    @group = submission.group
    @option = submission.option
    @target_group = submission.target_group
  end

  def check
    blocking_submission = find_blocking_submission
    
    if blocking_submission
      {
        queued: true,
        behind: blocking_submission,
        reason: queue_reason_for(blocking_submission)
      }
    else
      { queued: false }
    end
  end

  # Find submissions that were waiting on the processed submission
  def process_released
    released = Submission.pending.where(queued_behind_id: @submission.id)
    
    released.each do |queued_submission|
      # Clear the queue reference
      queued_submission.update!(queued_behind_id: nil, queue_reason: nil)
      
      # Broadcast that this submission is now processable
      ActionCable.server.broadcast("submissions_admin", {
        type: "queue_released",
        submission_id: queued_submission.id,
        was_blocked_by: @submission.id,
        blocker_status: @submission.status
      })
    end
    
    released
  end

  private

  def find_blocking_submission
    case @option.name
    when "hat Foto bemerkt"
      # Must wait for pending "hat Gruppe fotografiert" where:
      # - The photo was taken BY the target_group (they photographed us)
      # - OF our group
      find_pending_photo_of_us
    when "hat Gruppe fotografiert"
      # Must wait for pending "hat Foto bemerkt" where:
      # - The notice is FROM our target_group
      # - Against us
      # This ensures proper time ordering
      find_pending_notice_from_target
    else
      nil
    end
  end

  # For "hat Foto bemerkt": find pending photo submissions where target_group photographed our group
  def find_pending_photo_of_us
    return nil unless @target_group

    photo_option = Option.find_by(name: "hat Gruppe fotografiert")
    return nil unless photo_option

    # Find pending submission where:
    # - Option is "hat Gruppe fotografiert"
    # - The submitting group is @target_group (they claim to have photographed us)
    # - The target_group is @group (us)
    # - Submitted BEFORE our "hat Foto bemerkt"
    Submission.pending
              .where(option: photo_option)
              .where(group: @target_group)
              .where(target_group: @group)
              .where("submitted_at < ?", @submission.submitted_at)
              .order(submitted_at: :asc)
              .first
  end

  # For "hat Gruppe fotografiert": find pending notice from the group we photographed
  def find_pending_notice_from_target
    return nil unless @target_group

    notice_option = Option.find_by(name: "hat Foto bemerkt")
    return nil unless notice_option

    # Find pending submission where:
    # - Option is "hat Foto bemerkt"
    # - The submitting group is @target_group (the group we photographed)
    # - The target_group is @group (us, the photographer)
    # - Submitted BEFORE our photo submission
    Submission.pending
              .where(option: notice_option)
              .where(group: @target_group)
              .where(target_group: @group)
              .where("submitted_at < ?", @submission.submitted_at)
              .order(submitted_at: :asc)
              .first
  end

  def queue_reason_for(blocking_submission)
    case blocking_submission.option.name
    when "hat Gruppe fotografiert"
      "Wartet auf Foto-Verifizierung von #{blocking_submission.group.name}"
    when "hat Foto bemerkt"
      "Wartet auf 'Foto bemerkt' von #{blocking_submission.group.name}"
    else
      "Wartet auf #{blocking_submission.option.name}"
    end
  end
end
