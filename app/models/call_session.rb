class CallSession < ApplicationRecord
  # ─── Enums ──────────────────────────────────────────────────────────────────
  # call_type: audio-only vs video call.
  # TODO: enum :call_type, { audio: 0, video: 1 }

  # status: the 6-state lifecycle you designed.
  # calling  → initiator dialed, receiver hasn't been notified yet (offline/connecting)
  # ringing  → receiver is online and the call notification has been delivered
  # active   → at least one participant joined
  # ended    → host ended or everyone left
  # declined → callee explicitly rejected
  # missed   → no answer within 30s (Sidekiq job transitions calling/ringing → missed)
  # TODO: enum :status, { calling: 0, ringing: 1, active: 2, ended: 3, declined: 4, missed: 5 }

  # ─── Associations ───────────────────────────────────────────────────────────
  # TODO: belongs_to :conversation
  # TODO: belongs_to :initiator, class_name: "User"
  # (class_name needed — column is initiator_id but model is User)

  # TODO: has_many :call_participants, dependent: :destroy
  # TODO: has_many :participants, through: :call_participants, source: :user
  # (source: :user needed because the association is named :participants not :users)

  # ─── Validations ────────────────────────────────────────────────────────────
  # TODO: validates :call_type, presence: true
  # TODO: validates :status, presence: true
  # TODO: validates :conversation_id, presence: true

  # ended_at only makes sense if started_at exists.
  # if: :ended_at? fires only when ended_at is not nil.
  # TODO: validates :started_at, presence: true, if: :ended_at?

  # ─── Scopes ─────────────────────────────────────────────────────────────────
  # active_calls: calls currently in progress. Used by the conversation channel
  # to show the "call in progress" banner to latecomers.
  # TODO: scope :active_calls, -> { where(status: :active) }

  # ongoing: calls not yet terminated — calling, ringing, or active.
  # Used to prevent a second call from being started in the same conversation.
  # TODO: scope :ongoing, -> { where(status: [:calling, :ringing, :active]) }

  # ─── Instance methods ───────────────────────────────────────────────────────
  # duration returns how long the call lasted in seconds.
  # Returns nil if the call never started or is still active.
  # Used in call history serializer: { duration: call.duration }
  # TODO: def duration
  #         return nil unless started_at && ended_at
  #         (ended_at - started_at).to_i
  #       end
end
