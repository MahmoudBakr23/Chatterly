class UserBlueprint < Blueprinter::Base
  # Blueprinter serializes ActiveRecord models to JSON.
  # Define views to reuse the same class across different contexts:
  #   - default view   → used in message.user, search results (no email)
  #   - :public view   → same as default (public profile)
  #   - :with_email    → used in /users/me, login/register responses
  #
  # identifier sets the primary key field (always included in every view).
  identifier :id

  # ─── default / :public view ───────────────────────────────────────────────
  # Shown when displaying another user — no private fields.
  fields :username, :display_name, :avatar_url
  # Check Redis for presence key — true if the TTL key exists
  field :online do |user|
    redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/3"))
    redis.exists?("presence:#{user.id}")
  end
  # ─── :public view ─────────────────────────────────────────────────────────
  # Explicitly declared so Blueprinter doesn't raise on view: :public.
  # Empty block — inherits all default fields, no additions or exclusions.
  view :public do
  end

  # ─── :with_email view ─────────────────────────────────────────────────────
  # Used in /users/me, login response, and registration response.
  # Includes all default fields plus private fields.
  view :with_email do
    fields :email, :last_seen_at
  end
end
