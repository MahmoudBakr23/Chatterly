class CallParticipant < ApplicationRecord
  # ─── Associations ───────────────────────────────────────────────────────────
  belongs_to :call_session
  belongs_to :user
  # ─── Validations ────────────────────────────────────────────────────────────
  # joined_at is required — set by before_create below, never nil in the DB.
  validates :joined_at, presence: true
  # Prevent the same user from appearing twice in the same call.
  # The composite unique index [call_session_id, user_id] is the DB safety net.
  validates :user_id, uniqueness: { scope: :call_session_id,
                                    message: "is already in this call" }
  # ─── Callbacks ──────────────────────────────────────────────────────────────
  # Set joined_at automatically — never set it manually.
  # before_validation on: :create fires before validation on creation only,
  # ensuring joined_at is set before the presence check runs.
  before_validation :set_joined_at, on: :create
  # ─── Instance methods ───────────────────────────────────────────────────────
  # still_in_call? checks if this participant is still active.
  # left_at is nil while they're in the call, set when they leave.
  # Used by the call channel to show current participants list.
  def still_in_call?
    left_at.nil?
  end
  # participation_duration returns how long this person was in the call (seconds).
  # Falls back to Time.current if they haven't left yet (gives current duration).
  def participation_duration
    ((left_at || Time.current) - joined_at).to_i
  end

  private

  def set_joined_at
    self.joined_at = Time.current
  end
end
