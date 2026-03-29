class CallLogService
  # Creates a call-type message in the conversation for both participants to see,
  # then broadcasts it over the conversation WebSocket channel.
  #
  # Modelled after Messenger/Instagram: one message attributed to the initiator,
  # both sides receive it. The frontend decides the label ("You called" vs
  # "[Name] called") by comparing current_user.id with message.call_session.initiator_id.
  #
  # Idempotent: a second call to create! for the same call session is a no-op.
  # This protects against the two termination paths (REST controller + WS channel)
  # both firing in quick succession.
  def self.create!(call)
    return if Message.exists?(call_session_id: call.id, message_type: Message.message_types[:call])

    message = Message.new(
      conversation: call.conversation,
      user: call.initiator,
      message_type: :call,
      # content is required by the model's presence validation.
      # We store a placeholder — the UI renders from call_session data, not content.
      content: "call",
      call_session_id: call.id
    )
    # Assign the association object so the blueprint can access it without an
    # extra DB query during the immediate broadcast.
    message.call_session = call
    message.save!

    ActionCable.server.broadcast(
      "conversation_#{call.conversation_id}",
      { type: "new_message", message: MessageBlueprint.render_as_hash(message) }
    )

    message
  end
end
