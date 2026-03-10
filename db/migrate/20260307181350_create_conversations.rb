class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      # ─── Type discriminator ─────────────────────────────────────────────────
      # Integer enum — smaller than strings, mapped to names in the model:
      #   0 = channel  (public, anyone can join)
      #   1 = group    (private, invite-only)
      #   2 = direct   (DM, exactly 2 members, no name needed)
      t.integer :conversation_type, null: false, default: 0

      # ─── Metadata ───────────────────────────────────────────────────────────
      # Nullable intentionally — DMs have no name or description.
      # Model enforces: validates :name, presence: true, unless: :direct?
      t.string :name
      t.text :description

      # ─── Creator ────────────────────────────────────────────────────────────
      # t.references generates: created_by_id integer + foreign key constraint.
      # foreign_key: { to_table: :users } — PostgreSQL rejects rows pointing
      # to a non-existent user. Referential integrity at the DB level.
      t.references :created_by, null: false, foreign_key: { to_table: :users }, index: true
      # What's the difference between this reference line and the regular one. Is it the new column created_by_id? instead of just user_id?
      # [Claude] Yes — exactly right. t.references :name always generates a column called name_id.
      # So t.references :user       → column: user_id,       FK → users.id
      #    t.references :created_by → column: created_by_id, FK → ??? (Rails assumes a table called "created_bies" which doesn't exist!)
      # That's why we need foreign_key: { to_table: :users } — we're telling Rails/PostgreSQL
      # "this column is called created_by_id but it points at the users table, not created_bies."
      # We use :created_by instead of :user because a conversation has MULTIPLE user relationships:
      #   created_by_id → the user who created it
      #   members       → users who belong to it (via conversation_members)
      # If we used t.references :user we'd just get user_id which is ambiguous.
      # Named references make intent explicit and avoid column name collisions.

      t.timestamps null: false
    end

    # ─── Indexes — only where queries actually filter or sort ─────────────────
    # Rule: index columns that appear in WHERE, ORDER BY, or JOIN conditions.
    # Never index columns that are only ever displayed (read for output only).

    # conversation_type: we filter by this constantly — "show all channels",
    # "show all DMs for user X". Without index = full table scan every time.
    add_index :conversations, :conversation_type

    # name: useful for search ("find channel named #engineering") and
    # for the sidebar which sorts channels alphabetically by name.
    add_index :conversations, :name

    # description: REMOVED — nobody queries WHERE description = '...'
    # Description is display-only text. Indexing it wastes storage and
    # slows down INSERT/UPDATE with zero query performance benefit.

    # created_by_id: REMOVED — already created above by index: true in t.references.
    # Adding it again would create a DUPLICATE index → Rails raises an error on migrate.
    # t.references with index: true handles this automatically.
  end
end
