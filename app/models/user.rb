class User < ApplicationRecord
  # ─── Devise modules ─────────────────────────────────────────────────────────
  # Each module adds specific behavior:
  #   :database_authenticatable  → password hashing (bcrypt) + login verification
  #   :registerable              → sign up + account deletion
  #   :recoverable               → password reset via email token
  #   :rememberable              → remember-me token (we use JWT, but column kept)
  #   :validatable               → validates email format + password length
  #   :lockable                  → locks account after N failed attempts (devise.rb config)
  #   :jwt_authenticatable       → JWT strategy via devise-jwt gem
  #
  # jwt_revocation_strategy: tells devise-jwt HOW to revoke tokens on logout.
  # We use a custom Redis strategy (JwtDenylist) instead of a DB table —
  # Redis stores the revoked JTI with a TTL matching the token expiry.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # ─── Associations ───────────────────────────────────────────────────────────
  # dependent: :destroy means deleting a user cascades and deletes their data.
  # At scale, this would be a background job instead — destroying a user with
  # millions of messages should not happen in a single synchronous transaction.
  # For now, dependent: :destroy is correct for our scope.
  has_many :conversation_members, dependent: :destroy
  has_many :conversations, through: :conversation_members
  # created_conversations: all conversations this user created (created_by_id FK).
  # dependent: :nullify — when the user is deleted, set created_by_id to NULL and keep
  # the conversation alive. Other members and messages are unaffected.
  has_many :created_conversations, class_name: "Conversation",
                                   foreign_key: :created_by_id, dependent: :nullify
  has_many :messages, dependent: :destroy
  has_many :reactions, dependent: :destroy

  # initiated_calls and call_participations need explicit class_name because
  # the association name doesn't match the model name (same pattern as created_by)
  has_many :initiated_calls, class_name: "CallSession",
           foreign_key: "initiator_id", dependent: :destroy
  has_many :call_participations, class_name: "CallParticipant", dependent: :destroy

  # ─── Validations ────────────────────────────────────────────────────────────
  # :validatable (Devise) already validates email format and password length.
  # These are additional validations specific to our app.
  validates :username, presence: true,
                        uniqueness: { case_sensitive: false },
                        format: { with: /\A[a-z0-9_]+\z/,
                                  message: "only lowercase letters, numbers, and underscores" },
                        length: { minimum: 3, maximum: 30 }
  # display_name is optional — if blank, the UI falls back to username
  validates :display_name, length: { maximum: 50 }, allow_blank: true
  # ─── Callbacks ──────────────────────────────────────────────────────────────
  # Normalize username to lowercase BEFORE validation, not before_save.
  # before_save fires after validation — so 'DAVE' would fail the regex check first.
  # before_validation fires before validation runs, so the value is already
  # downcased by the time the format regex check sees it.
  before_validation :downcase_username
  # ─── Scopes ─────────────────────────────────────────────────────────────────
  # Scopes are reusable query fragments. They return an ActiveRecord::Relation
  # so they can be chained: User.online.where(...)
  #
  # online scope: users whose last_seen_at is within the last 5 minutes.
  # The index on last_seen_at (from migration) makes this query fast.
  # Note: 5.minutes.ago.. is a Ruby endless range (5 min ago → now)
  scope :online, -> { where(last_seen_at: 5.minutes.ago..) }
  # ─── Instance methods ───────────────────────────────────────────────────────
  # online? is the per-user predicate version of the scope above.
  # Used in serializers: { id: 1, username: "alice", online: user.online? }
  # Redis is the fast path — checked first. PostgreSQL is the fallback.
  def online?
    last_seen_at.present? && last_seen_at > 5.minutes.ago
  end

  private

  def downcase_username
    self.username = username.downcase if username.present?
  end
end
