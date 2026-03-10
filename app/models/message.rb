class Message < ApplicationRecord
  # ─── Associations ───────────────────────────────────────────────────────────
  # TODO: belongs_to :conversation
  # TODO: belongs_to :user

  # parent_message: self-referential association for threads.
  # optional: true because top-level messages have no parent.
  # TODO: belongs_to :parent_message, class_name: "Message", optional: true

  # TODO: has_many :reactions, dependent: :destroy

  # ─── Validations ────────────────────────────────────────────────────────────
  # TODO: validates :body, presence: true, length: { maximum: 4000 }
  # TODO: validates :conversation_id, presence: true
  # TODO: validates :user_id, presence: true

  # ─── Scopes ─────────────────────────────────────────────────────────────────
  # visible: excludes soft-deleted messages from normal queries.
  # deleted: the inverse — finds soft-deleted messages (admin/audit use).
  #
  # At scale, nearly every query goes through the visible scope.
  # The partial index on deleted_at IS NOT NULL makes the deleted scope fast too.
  # TODO: scope :visible, -> { where(deleted_at: nil) }
  # TODO: scope :deleted, -> { where.not(deleted_at: nil) }

  # recent: newest messages first. Used in API responses for chat history.
  # TODO: scope :recent, -> { order(created_at: :desc) }

  # ─── Instance methods ───────────────────────────────────────────────────────
  # deleted? checks if this specific message has been soft-deleted.
  # Used in serializers to decide what to render (e.g. "[message deleted]").
  # TODO: def deleted?
  #         deleted_at.present?
  #       end

  # soft_delete! marks the message as deleted without removing the DB row.
  # Why not destroy? Because:
  #   1. Reactions + threads reference this row — hard delete breaks them.
  #   2. Audit trail — moderation needs to see what was said.
  #   3. Partition safety — partitioned tables make cascading deletes expensive.
  # touch: false prevents updating updated_at (soft delete isn't an edit).
  # TODO: def soft_delete!
  #         update_columns(deleted_at: Time.current)
  #       end
end
