class MissedCallJob < ApplicationJob
  queue_as :default

  # Fired 30 seconds after a call is created (see CallSessionsController#create).
  # If the call is still ringing or calling at that point, nobody answered —
  # transition to :missed and drop the call log in the conversation.
  def perform(call_session_id)
    call = CallSession.includes(:conversation, :initiator).find_by(id: call_session_id)
    return unless call&.calling? || call&.ringing?

    call.update!(status: :missed)
    CallLogService.create!(call)
  end
end
