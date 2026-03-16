class CreateConversationMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_members do |t|
      # ─── Join table ─────────────────────────────────────────────────────────
      # This is the many-to-many join between users and conversations.
      # A user can belong to many conversations; a conversation has many users.
      # This table also carries extra data about the relationship (role, joined_at)
      # which is why we use a full model instead of a simple has_and_belongs_to_many.

      # TODO: add t.references :conversation, null: false, foreign_key: true, index: true
      # TODO: add t.references :user,         null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: false # false because the composite index is already created at the bottom.
      t.references :user,         null: false, foreign_key: true, index: true
      # ─── Role ───────────────────────────────────────────────────────────────
      # Integer enum: 0 = member, 1 = admin
      # Admins can delete messages and remove members.
      # The conversation creator is automatically assigned admin on creation.
      # TODO: add t.integer :role, null: false, default: 0
      t.integer :role, null: false, default: 0
      # ─── Timestamp ──────────────────────────────────────────────────────────
      # When this user joined. Used for "you joined 3 days ago" UI and
      # for filtering messages — show only messages after join date.
      # Not the same as created_at (which is when the row was inserted).
      # TODO: add t.datetime :joined_at
      t.datetime :joined_at
      t.timestamps null: false
    end

    # ─── Composite unique index ──────────────────────────────────────────────
    # A user can only be a member of a conversation once.
    # Composite index on both columns enforces this at the DB level AND
    # speeds up the query "is user X a member of conversation Y?" which
    # runs on EVERY authenticated request to conversation endpoints.
    # TODO: add_index :conversation_members, [:conversation_id, :user_id], unique: true
    add_index :conversation_members, [ :conversation_id, :user_id ], unique: true
  end
end
