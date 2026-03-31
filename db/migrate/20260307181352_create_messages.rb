class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    # ─── Why NOT create_table here ────────────────────────────────────────────
    # For time-based partitioning, PostgreSQL requires declaring the partition
    # strategy at table creation time using raw SQL — Rails' create_table DSL
    # doesn't support this directly. We use execute() for the raw DDL.
    #
    # PARTITIONING EXPLAINED:
    # Instead of one giant messages table, PostgreSQL splits rows into child
    # tables based on the partition key (created_at month).
    #
    # messages              ← parent table (logical, holds no rows directly)
    # ├── messages_2026_01  ← rows where created_at in Jan 2026
    # ├── messages_2026_02  ← rows where created_at in Feb 2026
    # └── messages_2026_03  ← rows where created_at in Mar 2026
    #
    # When you INSERT, PostgreSQL routes to the right partition automatically.
    # When you SELECT with a created_at filter, PostgreSQL only scans the
    # relevant partition — "partition pruning." Ignores all other partitions.
    #
    # Result: queries stay fast regardless of total message volume.

    # Raw SQL: creates the partitioned parent table with PARTITION BY RANGE (created_at).
    # PRIMARY KEY (id, created_at) — partition key must be part of the PK.
    # Why soft deletes (deleted_at)? Hard deleting at scale causes pagination gaps,
    # inconsistent cache invalidation, and no audit trail. Soft delete: set deleted_at = now().
    execute <<-SQL
    CREATE TABLE messages (
      id bigserial NOT NULL,
      content text NOT NULL,
      message_type integer NOT NULL DEFAULT 0,
      edited_at timestamptz,
      deleted_at timestamptz,
      conversation_id bigint NOT NULL,
      user_id bigint NOT NULL,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      PRIMARY KEY (id, created_at)
    ) PARTITION BY RANGE (created_at);
    SQL
    # ─── Create the first partition ──────────────────────────────────────────
    # Partitioned tables need at least one partition to accept writes.
    # We create this month's partition here. Future partitions are created
    # by a Sidekiq scheduled job that runs on the 1st of each month.
    execute <<-SQL
    CREATE TABLE messages_#{Time.current.strftime("%Y_%m")}
      PARTITION OF messages
      FOR VALUES FROM ('#{Time.current.beginning_of_month.iso8601}')
                    TO ('#{Time.current.next_month.beginning_of_month.iso8601}');
    SQL
    # ─── Indexes ──────────────────────────────────────────────────────────────
    # On partitioned tables, indexes must be created on the PARENT table.
    # PostgreSQL automatically applies them to every partition (current + future).

    # Most critical index: loading messages for a conversation in order.
    # "Give me the last 50 messages in conversation 5" runs on EVERY page load.
    # Composite index on (conversation_id, created_at) makes this O(log n).
    add_index :messages, [ :conversation_id, :created_at ]
    # Partial index on soft-deleted rows only (deleted_at IS NOT NULL).
    # Deleted messages are < 1% of total rows — this index stays tiny.
    # Serves admin/audit queries: "show all deleted messages in conversation X."
    # For normal queries (WHERE deleted_at IS NULL), the composite index on
    # [conversation_id, created_at] already handles filtering efficiently.
    add_index :messages, :deleted_at, where: "deleted_at IS NOT NULL", name: "index_messages_on_deleted_at"
    # Foreign key constraints on partitioned tables must be added separately
    add_foreign_key :messages, :conversations
    add_foreign_key :messages, :users
  end
end
