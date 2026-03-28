class CallChannel < ApplicationCable::Channel
  # CallChannel handles WebRTC signaling — the "matchmaking" layer that helps
  # two browsers establish a direct peer-to-peer connection.
  #
  # WebRTC primer:
  #   WebRTC is peer-to-peer — once connected, audio/video flows DIRECTLY between
  #   browsers without touching the server. But to SET UP that connection, both
  #   peers need to exchange three things via a signaling server (that's us):
  #     1. Offer/Answer (SDP) — describes each peer's media capabilities
  #     2. ICE candidates   — network paths (IPs/ports) each peer can be reached at
  #   Rails never sees the media stream — only these small JSON handshake messages.
  #
  # Stream design: personal streams ("calls_user_<user_id>")
  #   Each authenticated user subscribes to their own personal stream.
  #   The backend delivers incoming call notifications and WebRTC signals
  #   directly to the target user's personal stream, so they receive events
  #   regardless of which conversation (if any) they have open.
  #
  # Action flow:
  #   1. Initiator: REST POST /calls → broadcast incoming_call to each member's stream
  #   2. Recipient: receive incoming_call → show IncomingCallModal → click Accept
  #   3. Recipient: perform accept_call → backend creates participant + broadcasts call_accepted
  #   4. Initiator: receive call_accepted → get media → create offer → perform send_signal
  #   5. Recipient: receive signal(offer) → create answer → perform send_signal
  #   6. Both: exchange ICE candidates via send_signal
  #   7. WebRTC direct P2P connection established

  # ─── Subscribed ─────────────────────────────────────────────────────────────
  # Each user subscribes to their own personal stream — no call_session_id needed.
  # The stream is identified by current_user.id (set by ApplicationCable::Connection).
  def subscribed
    stream_from "calls_user_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  # ─── accept_call ────────────────────────────────────────────────────────────
  # Called by the recipient when they click Accept on the IncomingCallModal.
  # data: { call_session_id: <id> }
  #
  # Three things happen:
  #   1. A CallParticipant record is created for current_user.
  #   2. The call transitions ringing → active (stamped once via started_at guard).
  #   3. call_accepted is broadcast to the initiator's personal stream so they
  #      know to create the WebRTC offer.
  #
  # with_lock prevents two concurrent accept attempts from both passing the
  # ringing? guard before either commits (TOCTOU race condition).
  def accept_call(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call

    accepted = false
    call.with_lock do
      next unless call.ringing?

      CallParticipant.find_or_create_by!(call_session: call, user: current_user)
      call.update!(status: :active, started_at: call.started_at || Time.current)
      accepted = true
    end

    return unless accepted

    ActionCable.server.broadcast(
      "calls_user_#{call.initiator_id}",
      {
        type: "call_accepted",
        call_session_id: call.id,
        accepted_by: UserBlueprint.render_as_hash(current_user, view: :public)
      }
    )
  end

  # ─── decline_call ───────────────────────────────────────────────────────────
  # Called by the recipient when they click Decline on the IncomingCallModal.
  # data: { call_session_id: <id> }
  #
  # Transitions the call ringing → declined and notifies the initiator.
  def decline_call(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call

    declined = false
    call.with_lock do
      next unless call.ringing?

      call.update!(status: :declined)
      declined = true
    end

    return unless declined

    ActionCable.server.broadcast(
      "calls_user_#{call.initiator_id}",
      {
        type: "call_declined",
        call_session_id: call.id,
        declined_by: UserBlueprint.render_as_hash(current_user, view: :public)
      }
    )
  end

  # ─── send_signal ────────────────────────────────────────────────────────────
  # Relays a WebRTC signal (SDP offer/answer or ICE candidate) to the target user.
  # data: { target_user_id: <id>, call_session_id: <id>, signal: <signal_object> }
  #
  # The backend is a pure relay — it never inspects the signal content.
  # Signal types: { type: "offer", sdp: "..." }, { type: "answer", sdp: "..." },
  #               { type: "ice_candidate", candidate: { ... } }
  def send_signal(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call && participant?(call)

    ActionCable.server.broadcast(
      "calls_user_#{data['target_user_id']}",
      {
        type: "signal",
        call_session_id: data["call_session_id"],
        from_user_id: current_user.id,
        signal: data["signal"]
      }
    )
  end

  # ─── end_call ───────────────────────────────────────────────────────────────
  # Called by any participant when they hang up.
  # data: { call_session_id: <id> }
  #
  # Marks the session ended and broadcasts call_ended to all other participants
  # so their UIs tear down the WebRTC connection and dismiss the call overlay.
  def end_call(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call

    call.update!(status: :ended) unless call.ended?

    # Notify all participants except the one who ended the call
    participant_ids = call.participants.where.not(id: current_user.id).pluck(:id)
    # Also notify the initiator if they are not among the CallParticipant records
    # (e.g. the call was never accepted and the initiator is hanging up)
    notify_ids = (participant_ids + [ call.initiator_id ]).uniq - [ current_user.id ]

    notify_ids.each do |user_id|
      ActionCable.server.broadcast(
        "calls_user_#{user_id}",
        { type: "call_ended", call_session_id: call.id }
      )
    end
  end

  # ─── toggle_mute ────────────────────────────────────────────────────────────
  # Notifies other call participants that the current user toggled their mic.
  # data: { call_session_id: <id>, muted: true|false }
  def toggle_mute(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call && participant?(call)

    call.participants.where.not(id: current_user.id).pluck(:id).each do |user_id|
      ActionCable.server.broadcast(
        "calls_user_#{user_id}",
        {
          type: "participant_muted",
          call_session_id: call.id,
          user_id: current_user.id,
          muted: data["muted"]
        }
      )
    end
  end

  # ─── toggle_camera ──────────────────────────────────────────────────────────
  # Notifies other call participants that the current user toggled their camera.
  # data: { call_session_id: <id>, camera_off: true|false }
  def toggle_camera(data)
    call = CallSession.find_by(id: data["call_session_id"])
    return unless call && participant?(call)

    call.participants.where.not(id: current_user.id).pluck(:id).each do |user_id|
      ActionCable.server.broadcast(
        "calls_user_#{user_id}",
        {
          type: "participant_camera_toggled",
          call_session_id: call.id,
          user_id: current_user.id,
          camera_off: data["camera_off"]
        }
      )
    end
  end

  private

  # participant? — true if current_user is a CallParticipant OR the initiator.
  # Used to prevent signal relay from/to unauthorised users.
  def participant?(call)
    call.participants.exists?(user: current_user) ||
      call.initiator_id == current_user.id
  end
end
