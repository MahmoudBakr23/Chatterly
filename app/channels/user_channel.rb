class UserChannel < ApplicationCable::Channel
  # UserChannel delivers cross-conversation notifications to each authenticated user
  # on their personal stream ("user_<id>").
  #
  # Why a personal stream?
  #   Some events don't belong to a specific conversation stream (the user isn't
  #   subscribed yet) or a call stream. Examples:
  #     - new_conversation: someone added this user to a new DM or group —
  #       the user has no conversation subscription yet, so we push the full
  #       ConversationWithMembers payload here so the sidebar updates in real time.
  #
  # Pattern: identical to CallChannel — one subscription per authenticated session,
  # mounted in app/(app)/layout.tsx via useUserChannel().

  def subscribed
    stream_from "user_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
