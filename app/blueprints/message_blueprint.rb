class MessageBlueprint < Blueprinter::Base
  identifier :id

  # ─── default view ─────────────────────────────────────────────────────────
  # Used in GET /messages (list), new_message and message_edited WebSocket events.
  # Includes the author (via UserBlueprint) and all reactions inline.
  #
  # Why include reactions here instead of lazy-loading?
  #   The UI renders message + reactions together in one shot.
  #   If reactions were a separate request, each message row would trigger an
  #   extra HTTP call (N+1 at the API level). Bundling them is cheaper.
  #
  # TODO: fields :content, :message_type, :edited_at, :created_at, :parent_message_id
  fields :content, :message_type, :edited_at, :created_at, :parent_message_id
  # TODO: field :user do |message|
  #         UserBlueprint.render_as_hash(message.user, view: :public)
  #       end
  field :user do |message|
    UserBlueprint.render_as_hash(message.user, view: :public)
  end
  # TODO: field :reactions do |message|
  #         ReactionBlueprint.render_as_hash(message.reactions)
  #       end
  field :reactions do |message|
    ReactionBlueprint.render_as_hash(message.reactions)
  end
end
