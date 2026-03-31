class ConversationMember < ApplicationRecord
  # ─── Enums ──────────────────────────────────────────────────────────────────
  enum :role, { member: 0, admin: 1 }
  # ─── Associations ───────────────────────────────────────────────────────────
  belongs_to :conversation
  belongs_to :user
  # ─── Validations ────────────────────────────────────────────────────────────
  # Model-level uniqueness guard — the DB composite unique index is the final
  # safety net, but this gives a clean validation error before hitting the DB.
  # scope: :conversation_id means "user_id must be unique within each conversation"
  validates :user_id, uniqueness: { scope: :conversation_id,
                                     message: "is already a member of this conversation" }
  # ─── Callbacks ──────────────────────────────────────────────────────────────
  # Set joined_at automatically on creation — never manually.
  # before_create fires inside the transaction, before the INSERT.
  before_create { self.joined_at = Time.current }
end
