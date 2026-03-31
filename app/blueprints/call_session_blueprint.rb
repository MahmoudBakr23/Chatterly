class CallSessionBlueprint < Blueprinter::Base
  identifier :id

  # ─── default view ─────────────────────────────────────────────────────────
  # Used in POST /calls (create) and incoming_call WebSocket event.
  # No participants yet (call just started).
  fields :conversation_id, :initiator_id, :call_type, :status, :created_at
  # ─── :with_participants view ──────────────────────────────────────────────
  # Used in GET /calls/active — shows who is already in the call.
  # Needed for the "join late" flow: user opens the conversation, sees active
  # call with participants listed, clicks "Join".
  view :with_participants do
    field :started_at do |call|
      call.call_participants.minimum(:joined_at)
    end
    field :participants do |call|
      UserBlueprint.render_as_hash(call.participants, view: :public)
    end
  end
end
