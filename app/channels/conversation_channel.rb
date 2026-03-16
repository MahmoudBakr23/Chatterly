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
  # TODO: def subscribed
  #         conversation = Conversation.find_by(id: params[:conversation_id])
  #         return reject unless conversation && member?(conversation)
  #         stream_from "conversation_#{conversation.id}"
  #       end

  # ─── Unsubscribed ───────────────────────────────────────────────────────────
  # Called when the client unsubscribes or disconnects.
  # stop_all_streams cleans up Redis subscriptions for this channel instance.
  # TODO: def unsubscribed
  #         stop_all_streams
  #       end

  private

  # member? checks if the current_user is a member of the conversation.
  # Prevents users from subscribing to conversations they don't belong to.
  # TODO: def member?(conversation)
  #         conversation.members.exists?(current_user.id)
  #       end
end
