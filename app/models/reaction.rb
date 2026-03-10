class Reaction < ApplicationRecord
  # ─── Associations ───────────────────────────────────────────────────────────
  # belongs_to :message normally adds a foreign key check. But reactions.rb
  # migration set foreign_key: false on message_id because the messages table
  # has a composite primary key (id, created_at) — PostgreSQL FK must reference
  # ALL parts of the PK, not just id. We skip the FK at the DB level, so we
  # also tell Rails not to validate it via foreign_key: false here... wait,
  # actually belongs_to in Rails doesn't hit the DB for FK validation — that's
  # the DB constraint. belongs_to just adds a validation that message_id is present.
  # The message_created_at column is what we use to route to the right partition.
  # TODO: belongs_to :message
  # TODO: belongs_to :user

  # ─── Validations ────────────────────────────────────────────────────────────
  # emoji must be present — we store the actual Unicode character (e.g. "👍"),
  # not a code like ":thumbsup:". Max 10 chars covers multi-byte emoji sequences.
  # TODO: validates :emoji, presence: true, length: { maximum: 10 }

  # The composite unique index [message_id, user_id, emoji] is the DB safety net.
  # This validation gives a clean error before hitting the DB.
  # A user can react to the same message with DIFFERENT emojis — that's intentional.
  # scope: [:message_id, :emoji] means "user_id must be unique per message+emoji combo"
  # TODO: validates :user_id, uniqueness: { scope: [:message_id, :emoji],
  #                                         message: "already reacted with this emoji" }

  # message_created_at must be present — without it we can't locate the right
  # partition to look up the message. The controller should always pass this.
  # TODO: validates :message_created_at, presence: true
end
