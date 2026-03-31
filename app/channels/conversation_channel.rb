class ConversationChannel < ApplicationCable::Channel
  # ConversationChannel streams real-time events for a single conversation:
  # new messages, edits, soft deletes, and reactions.
  #
  # Pub/Sub flow (recap):
  #   1. Client subscribes → subscribed runs, we stream from a Redis channel
  #   2. Controller creates a message → broadcasts to that Redis channel
  #   3. Action Cable fan-out → every subscribed client receives the payload
  #
  # Stream name format: "conversation_<id>"
  # Keeps each conversation isolated — broadcasting to conversation_1 only
  # reaches clients subscribed to conversation_1.

  # ─── Subscribed ─────────────────────────────────────────────────────────────
  # Called when the client subscribes. params[:conversation_id] comes from
  # the frontend: consumer.subscriptions.create({ channel: "ConversationChannel",
  #                                               conversation_id: 1 })
  # We verify membership before streaming — no leaking private conversations.
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])
    return reject unless conversation && member?(conversation)
    stream_from "conversation_#{conversation.id}"
  end
  # ─── Unsubscribed ───────────────────────────────────────────────────────────
  # Called when the client unsubscribes or disconnects.
  # stop_all_streams cleans up Redis subscriptions for this channel instance.
  def unsubscribed
    stop_all_streams
  end

  # ─── typing ──────────────────────────────────────────────────────────────────
  # Called by the client when the user STARTS typing (first keystroke after idle).
  # Broadcasts a typing_start event to all OTHER members of the conversation.
  # The receiver shows "X is typing…" immediately and clears it on typing_stop.
  # This mirrors the Messenger/Instagram approach: logical start/stop events,
  # NOT a repeated heartbeat with a receiver-side auto-clear timer.
  def typing
    conversation = Conversation.find_by(id: params[:conversation_id])
    return unless conversation && member?(conversation)

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "typing_start",
        user_id: current_user.id,
        display_name: current_user.display_name.presence || current_user.username
      }
    )
  end

  # ─── stop_typing ─────────────────────────────────────────────────────────────
  # Called by the client when the user STOPS typing — message sent, input cleared,
  # or input blurred. Broadcasts a typing_stop event so receivers clear the indicator
  # immediately without waiting for any timeout.
  def stop_typing
    conversation = Conversation.find_by(id: params[:conversation_id])
    return unless conversation && member?(conversation)

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type: "typing_stop",
        user_id: current_user.id
      }
    )
  end

  private

  # member? checks if the current_user is a member of the conversation.
  # Prevents users from subscribing to conversations they don't belong to.
  def member?(conversation)
    conversation.members.exists?(current_user.id)
  end
end
