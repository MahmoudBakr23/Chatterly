class ReactionBlueprint < Blueprinter::Base
  identifier :id

  # ─── default view ─────────────────────────────────────────────────────────
  # Used inline inside MessageBlueprint and in reaction_added WebSocket events.
  fields :emoji, :message_id, :user_id
end
