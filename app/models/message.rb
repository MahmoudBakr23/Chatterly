class Message < ApplicationRecord
  # ─── Associations ───────────────────────────────────────────────────────────
  belongs_to :conversation
  belongs_to :user
  # parent_message: self-referential association for threads.
  # optional: true because top-level messages have no parent.
  belongs_to :parent_message, class_name: "Message", optional: true
  # What is this parent_message thing, please answer with a practical example briefly!
  # [Claude] It's for threaded replies — like Slack threads. Example:
  # Message #1 (id: 1): "Anyone free for a call?" → parent_message_id: nil  (top-level)
  # Message #2 (id: 2): "Yes, give me 5 mins!"    → parent_message_id: 1   (reply to #1)
  # Message #3 (id: 3): "Same!"                   → parent_message_id: 1   (reply to #1)
  # Messages #2 and #3 are grouped under #1 in the UI as a thread.
  has_many :reactions, dependent: :destroy
  # call_session: present only on call-type messages. The call log message is
  # attributed to the initiator and carries the session for duration/status/type.
  # No FK constraint in the DB (partitioned table limitation) — enforced in app.
  belongs_to :call_session, optional: true
  # ─── Enums ──────────────────────────────────────────────────────────────────
  # call (3): a system-generated message that logs a call in the conversation feed.
  # The frontend reads call_session nested data — content field is ignored.
  enum :message_type, { text: 0, image: 1, file: 2, call: 3 }, scopes: false

  # ─── Validations ────────────────────────────────────────────────────────────
  validates :content, presence: true, length: { maximum: 4000 }
  validates :conversation_id, presence: true
  validates :user_id, presence: true
  # ─── Scopes ─────────────────────────────────────────────────────────────────
  # visible: excludes soft-deleted messages from normal queries.
  # deleted: the inverse — finds soft-deleted messages (admin/audit use).
  #
  # At scale, nearly every query goes through the visible scope.
  # The partial index on deleted_at IS NOT NULL makes the deleted scope fast too.
  scope :visible, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  # recent: newest messages first. Used in API responses for chat history.
  scope :recent, -> { order(created_at: :desc) }
  # ─── Instance methods ───────────────────────────────────────────────────────
  # deleted? checks if this specific message has been soft-deleted.
  # Used in serializers to decide what to render (e.g. "[message deleted]").
  def deleted?
    deleted_at.present?
  end
  # soft_delete! marks the message as deleted without removing the DB row.
  # Why not destroy? Because:
  #   1. Reactions + threads reference this row — hard delete breaks them.
  #   2. Audit trail — moderation needs to see what was said.
  #   3. Partition safety — partitioned tables make cascading deletes expensive.
  # touch: false prevents updating updated_at (soft delete isn't an edit).
  def soft_delete!
    update_columns(deleted_at: Time.current)
  end
end
