class MessageBlueprint < Blueprinter::Base
  # Messages live in a partitioned table with composite PK (id, created_at).
  # Calling .id on a partitioned record returns [id, created_at] — we override
  # to return only the integer id so the frontend receives a plain number.
  identifier(:id) { |message| message.read_attribute(:id) }

  # ─── default view ─────────────────────────────────────────────────────────
  # Used in GET /messages (list), new_message and message_edited WebSocket events.
  # Includes the author (via UserBlueprint) and all reactions inline.
  #
  # Why include reactions here instead of lazy-loading?
  #   The UI renders message + reactions together in one shot.
  #   If reactions were a separate request, each message row would trigger an
  #   extra HTTP call (N+1 at the API level). Bundling them is cheaper.
  #
  # message_type is a Rails enum — call the method explicitly so Blueprinter
  # returns the string ("text") rather than the raw integer (0).
  fields :content, :edited_at, :created_at, :parent_message_id
  field(:message_type) { |message| message.message_type }
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
