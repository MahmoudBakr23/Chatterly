# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # ─── Devise auth columns (do not touch) ─────────────────────────────────
      # encrypted_password: bcrypt hash of the user's password.
      # bcrypt is a one-way hash — you can never reverse it to get the original.
      # On login, Rails hashes the submitted password and compares hashes.
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      # Password reset flow — token emailed to user, expires after use
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at

      # Lockable — tracks failed login attempts (configured in devise.rb)
      # TODO: uncomment these three lines to enable account locking
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      # ─── Chatterly custom columns ────────────────────────────────────────────

      # username: unique handle used for @mentions and profile URLs.
      # null: false — every user must have one.
      # lowercase only, enforced at model validation level.
      # TODO: add t.string :username with null: false constraint
      # TODO: add t.string :display_name (nullable — shown in UI instead of username)
      # TODO: add t.string :avatar_url   (nullable — URL pointing to Cloudflare R2)
      t.string :username, null: false
      t.string :display_name, null: true
      t.string :avatar_url, null: true

      # last_seen_at: the heartbeat column for our presence system.
      # Updated on every API request via a before_action in BaseController.
      # User is considered "online" if last_seen_at > 5.minutes.ago.
      # Stored here in PostgreSQL as the durable record.
      # Redis presence key (user:42:online) is the fast-path check — if Redis
      # misses, we fall back to this column.
      # TODO: add t.datetime :last_seen_at (nullable — null means never seen)
      t.datetime :last_seen_at, null: true
      t.timestamps null: false
    end

    # ─── Indexes ──────────────────────────────────────────────────────────────
    # Indexes are B-tree data structures that let PostgreSQL find rows without
    # scanning the entire table. Think of them as a book's index — jump straight
    # to the page instead of reading every page.
    #
    # unique: true = PostgreSQL enforces uniqueness at the DB level, not just Rails.
    # Always enforce critical uniqueness constraints at BOTH levels (model + DB).
    # Rails validations can have race conditions under concurrent requests.
    # The DB unique index is the final safety net.

    # Devise requires these two — email for login lookup, token for password reset
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
    
    # TODO: add a unique index on :username
    # Case-insensitive uniqueness is handled at the model level (validates :username,
    # uniqueness: { case_sensitive: false }) but the DB index is case-sensitive.
    # That's fine — we normalize usernames to lowercase before saving.
    add_index :users, :username, unique: true
    # TODO: add an index on :last_seen_at
    add_index :users, :last_seen_at
    # Why? We'll query "all users where last_seen_at > 5.minutes.ago" for presence.
    # Without an index, that scans the entire users table on every presence check.
    # With an index, PostgreSQL jumps directly to recent rows.
  end
end
