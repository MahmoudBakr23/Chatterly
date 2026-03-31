class CreateCallParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :call_participants do |t|
      # ─── Which call ─────────────────────────────────────────────────────────
      t.references :call_session, null: false, foreign_key: true, index: false # false because the composite index is already created at the bottom.
      # ─── Which user ─────────────────────────────────────────────────────────
      t.references :user, null: false, foreign_key: true, index: true
      # ─── Participation window ────────────────────────────────────────────────
      # joined_at: when this user joined the call
      # left_at:   when they left (null = still in the call)
      # These two together give you call duration per participant and
      # let you distinguish "currently in call" vs "was in call"
      t.datetime :joined_at, null: false
      t.datetime :left_at
      t.timestamps null: false
    end

    # Prevent a user from appearing twice in the same call
    add_index :call_participants, [ :call_session_id, :user_id ], unique: true
  end
end
