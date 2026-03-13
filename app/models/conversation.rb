class Conversation < ApplicationRecord
  # ─── Enums ──────────────────────────────────────────────────────────────────
  # enum maps integer values in the DB to named symbols in Ruby.
  # Gives you: conversation.channel? conversation.direct? conversation.group?
  # Also generates scopes: Conversation.channel, Conversation.direct
  # The integer values must match exactly what's in the migration (default: 0 = channel)
  # TODO: enum :conversation_type, { channel: 0, group: 1, direct: 2 }
  # scopes: false — disables auto-generated class method scopes (e.g. Conversation.group)
  # because :group conflicts with ActiveRecord's built-in .group() SQL method.
  # We still get predicate methods: channel? direct? group? — which is all we need.
  enum :conversation_type, { channel: 0, group: 1, direct: 2 }, scopes: false
  # ─── Associations ───────────────────────────────────────────────────────────
  # TODO: belongs_to :created_by, class_name: "User"
  # (class_name needed — column is created_by_id but model is User, not CreatedBy)
  # optional: true because created_by_id can be NULL if the creator's account was deleted.
  belongs_to :created_by, class_name: "User", optional: true
  # TODO: has_many :conversation_members, dependent: :destroy
  # TODO: has_many :members, through: :conversation_members, source: :user
  # (source: :user needed because the association is named :members not :users)
  has_many :conversation_members, dependent: :destroy
  has_many :members, through: :conversation_members, source: :user
  # TODO: has_many :messages, dependent: :destroy
  has_many :messages, dependent: :destroy
  # TODO: has_many :call_sessions, dependent: :destroy
  has_many :call_sessions, dependent: :destroy
  # ─── Validations ────────────────────────────────────────────────────────────
  # name is required for channels and groups, but NOT for direct messages.
  # unless: :direct? uses the enum predicate method generated above.
  # TODO: validates :name, presence: true, unless: :direct?
  # TODO: validates :conversation_type, presence: true
  # TODO: validates :name, length: { maximum: 100 }, allow_blank: true
  validates :name, presence: true, unless: :direct?
  validates :conversation_type, presence: true
  validates :name, length: { maximum: 100 }, allow_blank: true
end
