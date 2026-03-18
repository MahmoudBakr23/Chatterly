class ConversationBlueprint < Blueprinter::Base
  identifier :id

  # ─── default view ─────────────────────────────────────────────────────────
  # Used in GET /conversations (list). Lightweight — no member array.
  # member_count is a scalar; no N+1 because we can use counter_cache or a
  # subquery. For now, a direct count is fine (optimize later with counter_cache).
  #
  # TODO: fields :name, :description, :conversation_type, :created_by_id, :created_at
  # TODO: field :member_count do |conversation|
  #         conversation.members.count
  #       end

  # ─── :with_members view ───────────────────────────────────────────────────
  # Used in GET /conversations/:id (show) and after create.
  # Nests the full member list — each member rendered via UserBlueprint :public.
  #
  # association :members does not automatically use another blueprint.
  # We use a block to delegate to UserBlueprint explicitly.
  #
  # TODO: view :with_members do
  #         field :members do |conversation|
  #           UserBlueprint.render_as_hash(conversation.members, view: :public)
  #         end
  #       end
end
