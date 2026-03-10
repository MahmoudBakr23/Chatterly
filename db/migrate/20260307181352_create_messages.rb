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

    # TODO: Write the raw SQL to create the partitioned parent table.
    # Use execute() to run raw SQL — Rails falls back to this for unsupported DDL.
    # The SQL should:
    #   1. CREATE TABLE messages with all columns
    #   2. Add PARTITION BY RANGE (created_at) at the end
    #
    # Columns to include:
    #   id            bigserial NOT NULL          (auto-incrementing primary key)
    #   content       text NOT NULL               (the message body)
    #   message_type  integer NOT NULL DEFAULT 0  (0=text, 1=system)
    #   edited_at     timestamptz                 (null until edited)
    #   deleted_at    timestamptz                 (null until soft-deleted — we NEVER hard delete messages)
    #   conversation_id bigint NOT NULL           (FK to conversations)
    #   user_id         bigint NOT NULL           (FK to users)
    #   created_at    timestamptz NOT NULL        (PARTITION KEY — must be in primary key)
    #   updated_at    timestamptz NOT NULL
    #   PRIMARY KEY (id, created_at)              (partition key must be part of PK)
    #
    # Why soft deletes (deleted_at)?
    # Hard deleting a message at scale causes:
    #   - Gaps in pagination (page 2 suddenly has different rows)
    #   - Other users who cached the message see it disappear inconsistently
    #   - No audit trail
    # Soft delete: set deleted_at = now(). Query filters WHERE deleted_at IS NULL.
    # The row stays. It just becomes invisible. Recoverable. Consistent.

    # TODO: execute <<-SQL
    #   CREATE TABLE messages (
    #     ... your columns here ...
    #   ) PARTITION BY RANGE (created_at);
    # SQL
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
    # TODO: execute <<-SQL
    #   CREATE TABLE messages_#{Time.current.strftime("%Y_%m")}
    #     PARTITION OF messages
    #     FOR VALUES FROM ('#{Time.current.beginning_of_month.iso8601}')
    #                   TO ('#{Time.current.next_month.beginning_of_month.iso8601}');
    # SQL
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
    # TODO: add_index :messages, [:conversation_id, :created_at]
    add_index :messages, [:conversation_id, :created_at]
    # Partial index on soft-deleted rows only (deleted_at IS NOT NULL).
    # Deleted messages are < 1% of total rows — this index stays tiny.
    # Serves admin/audit queries: "show all deleted messages in conversation X."
    # For normal queries (WHERE deleted_at IS NULL), the composite index on
    # [conversation_id, created_at] already handles filtering efficiently.
    # TODO: add_index :messages, :deleted_at, where: "deleted_at IS NOT NULL", name: "index_messages_on_deleted_at"
    add_index :messages, :deleted_at, where: "deleted_at IS NOT NULL", name: "index_messages_on_deleted_at"
    # Foreign key constraints on partitioned tables must be added separately
    # TODO: add_foreign_key :messages, :conversations
    # TODO: add_foreign_key :messages, :users
    add_foreign_key :messages, :conversations
    add_foreign_key :messages, :users
  end
end
