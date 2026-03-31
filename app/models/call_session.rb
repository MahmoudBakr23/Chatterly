class CallSession < ApplicationRecord
  # ─── Enums ──────────────────────────────────────────────────────────────────
  # call_type: audio-only vs video call.
  enum :call_type, { audio: 0, video: 1 }
  # status: the 6-state lifecycle you designed.
  # calling  → initiator dialed, receiver hasn't been notified yet (offline/connecting)
  # ringing  → receiver is online and the call notification has been delivered
  # active   → at least one participant joined
  # ended    → host ended or everyone left
  # declined → callee explicitly rejected
  # missed   → no answer within 30s (Sidekiq job transitions calling/ringing → missed)
  enum :status, { calling: 0, ringing: 1, active: 2, ended: 3, declined: 4, missed: 5 }
  # ─── Associations ───────────────────────────────────────────────────────────
  # (class_name needed — column is initiator_id but model is User)
  belongs_to :conversation
  belongs_to :initiator, class_name: "User"
  # (source: :user needed because the association is named :participants not :users)
  has_many :call_participants, dependent: :destroy
  has_many :participants, through: :call_participants, source: :user
  # ─── Validations ────────────────────────────────────────────────────────────
  validates :call_type, presence: true
  validates :status, presence: true
  validates :conversation_id, presence: true
  # ended_at only makes sense if started_at exists.
  # if: :ended_at? fires only when ended_at is not nil.
  validates :started_at, presence: true, if: :ended_at?
  # Q: How we're going to set the start_at of the call only after the end_at is determined?
  # [Claude] The validation reads backwards — it means "if ended_at is present, started_at must also be present."
  # In practice: started_at is set by the controller when status transitions to :active (first participant joins).
  # ended_at is set later when status transitions to :ended. The validation just enforces that you can't
  # have an ended_at without a started_at — i.e. you can't end a call that never started.
  # ─── Scopes ─────────────────────────────────────────────────────────────────
  # active_calls: calls currently in progress. Used by the conversation channel
  # to show the "call in progress" banner to latecomers.
  scope :active_calls, -> { where(status: :active) }
  # ongoing: calls not yet terminated — calling, ringing, or active.
  # Used to prevent a second call from being started in the same conversation.
  scope :ongoing, -> { where(status: [ :calling, :ringing, :active ]) }
  # ─── Instance methods ───────────────────────────────────────────────────────
  # duration returns how long the call lasted in seconds.
  # Returns nil if the call never started or is still active.
  # Used in call history serializer: { duration: call.duration }
  def duration
    return nil unless started_at && ended_at
    (ended_at - started_at).to_i
  end
end
