class CreateCallSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :call_sessions do |t|
      # ─── Where the call is happening ────────────────────────────────────────
      # TODO: add t.references :conversation, null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: false # false because the composite index is already created at the bottom.
      # ─── Who started it ─────────────────────────────────────────────────────
      # Can't use t.references :initiator because the column name doesn't match
      # the table name (users). We name the column explicitly.
      # TODO: add t.references :initiator, null: false, foreign_key: { to_table: :users }, index: true
      t.references :initiator, null: false, foreign_key: { to_table: :users }, index: true
      # ─── Call type ──────────────────────────────────────────────────────────
      # Integer enum: 0 = audio, 1 = video
      # TODO: add t.integer :call_type, null: false, default: 0
      t.integer :call_type, null: false, default: 0
      # ─── Status lifecycle ───────────────────────────────────────────────────
      # Integer enum tracking where the call is in its lifecycle:
      #   0 = calling   (initiated, waiting for someone to answer but that someone is still offline)
      #   1 = ringing   (initiated, waiting for someone to pick up)
      #   2 = active    (at least one other person joined)
      #   3 = ended     (host ended or everyone left)
      #   4 = declined  (callee explicitly rejected)
      #   5 = missed    (no one answered within 30 seconds — set by Sidekiq job)
      # TODO: add t.integer :status, null: false, default: 0
      t.integer :status, null: false, default: 0
      # ─── Timestamps ─────────────────────────────────────────────────────────
      # started_at: when the first participant joined (transitioned to active)
      # ended_at:   when the call ended — useful for call duration history
      # Both nullable — ringing calls haven't started or ended yet
      # TODO: add t.datetime :started_at
      # TODO: add t.datetime :ended_at
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps null: false
    end

    # Index for "is there an active call in this conversation?" query
    # Runs when a user opens a conversation that might have an ongoing call
    # TODO: add_index :call_sessions, [:conversation_id, :status]
    add_index :call_sessions, [:conversation_id, :status]
    # check line 6: The conversation_id is not indexed because the composite index is already created here,
    # and the leftmost column is already the conversation_id.
  end
end
