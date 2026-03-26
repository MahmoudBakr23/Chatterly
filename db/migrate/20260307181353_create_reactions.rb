class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :reactions do |t|
      # ─── What's being reacted to ────────────────────────────────────────────
      # References a message. Note: message_id alone isn't enough to locate a
      # partitioned message row — we also need created_at (the partition key).
      # We store message_created_at here so we can query the right partition
      # without doing a full table scan across all partitions.
      # TODO: add t.references :message, null: false, foreign_key: false, index: true
      t.references :message, null: false, foreign_key: false, index: false
      # (foreign_key: false because FK constraints on partitioned tables are limited)
      # What's that supposed to mean? Isn't the message_id is the FK to the messages table?
      # [Claude] Yes, message_id IS the logical foreign key — it points at messages.
      # But we can't create a database-level FK constraint here for one specific reason:
      # our messages table has PRIMARY KEY (id, created_at) — a composite PK.
      # PostgreSQL FK constraints must reference the FULL primary key or a unique constraint.
      # Since id alone is not the full PK, a FK to just messages(id) would fail.
      # So foreign_key: false tells Rails "don't create the constraint at the DB level."
      # Referential integrity is handled at the application level instead —
      # the model ensures message_id always points to a real message before saving.
      # This is also why we store message_created_at — we need BOTH id AND created_at
      # to locate a row in a partitioned table without scanning all partitions.
      #
      # index: false — the composite unique index [message_id, user_id, emoji] below
      # already has message_id as its leftmost column, so it covers message_id-only
      # lookups ("get all reactions for message X") with zero extra index needed.
      # TODO: add t.datetime :message_created_at, null: false
      t.datetime :message_created_at, null: false
      # ─── Who reacted ────────────────────────────────────────────────────────
      # TODO: add t.references :user, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      # ─── The reaction itself ─────────────────────────────────────────────────
      # Stored as the emoji character itself ("👍") not a code (":thumbsup:").
      # Keeps it simple, frontend-agnostic, and future-proof.
      # TODO: add t.string :emoji, null: false
      t.string :emoji, null: false
      t.timestamps null: false
    end

    # ─── Unique constraint ───────────────────────────────────────────────────
    # One user can only react with the same emoji once per message.
    # Composite unique index enforces this at the DB level.
    # The model also validates this, but the DB index is the race-condition guard.
    # TODO: add_index :reactions, [:message_id, :user_id, :emoji], unique: true
    add_index :reactions, [ :message_id, :user_id, :emoji ], unique: true
  end
end
