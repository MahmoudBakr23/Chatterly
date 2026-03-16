class CallChannel < ApplicationCable::Channel
  # CallChannel handles WebRTC signaling — the "matchmaking" layer that helps
  # two browsers establish a direct peer-to-peer connection.
  #
  # WebRTC primer (you need this to understand the flow below):
  #   WebRTC is peer-to-peer — once connected, audio/video flows DIRECTLY between
  #   browsers without touching the server. But to SET UP that connection, both
  #   peers need to exchange three things via a signaling server (that's us):
  #     1. Offer/Answer (SDP) — describes each peer's media capabilities
  #     2. ICE candidates   — network paths (IPs/ports) each peer can be reached at
  #   Rails never sees the media stream — only these small JSON handshake messages.
  #
  # Stream name format: "call_<call_session_id>"
  # All participants in the same call share one stream.

  # ─── Subscribed ─────────────────────────────────────────────────────────────
  # TODO: def subscribed
  #         call = CallSession.find_by(id: params[:call_session_id])
  #         return reject unless call && participant?(call)
  #         stream_from "call_#{call.id}"
  #       end

  # ─── Unsubscribed ───────────────────────────────────────────────────────────
  # TODO: def unsubscribed
  #         stop_all_streams
  #       end

  # ─── offer ──────────────────────────────────────────────────────────────────
  # Caller sends their SDP offer to the callee via the server.
  # data: { call_session_id:, sdp: <offer> }
  # We rebroadcast to everyone else in the call stream — callee picks it up.
  # TODO: def offer(data)
  #         ActionCable.server.broadcast("call_#{data['call_session_id']}", {
  #           type: "offer",
  #           sdp: data["sdp"],
  #           from: current_user.id
  #         })
  #       end

  # ─── answer ─────────────────────────────────────────────────────────────────
  # Callee responds with their SDP answer — completes the capability negotiation.
  # data: { call_session_id:, sdp: <answer> }
  # TODO: def answer(data)
  #         ActionCable.server.broadcast("call_#{data['call_session_id']}", {
  #           type: "answer",
  #           sdp: data["sdp"],
  #           from: current_user.id
  #         })
  #       end

  # ─── ice_candidate ──────────────────────────────────────────────────────────
  # Both peers continuously send ICE candidates as they discover network paths.
  # The other peer tries each candidate until a direct connection is established.
  # data: { call_session_id:, candidate: <ICE candidate object> }
  # TODO: def ice_candidate(data)
  #         ActionCable.server.broadcast("call_#{data['call_session_id']}", {
  #           type: "ice_candidate",
  #           candidate: data["candidate"],
  #           from: current_user.id
  #         })
  #       end

  private

  # Only participants of the call can subscribe — no uninvited listeners.
  # TODO: def participant?(call)
  #         call.participants.exists?(current_user.id) ||
  #           call.initiator_id == current_user.id
  #       end
end
