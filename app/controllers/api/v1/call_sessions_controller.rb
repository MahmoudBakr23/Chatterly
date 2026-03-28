module Api
  module V1
    class CallSessionsController < BaseController
      before_action :set_conversation

      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/conversations/:conversation_id/calls
      # Body: { call: { call_type: "video" } }
      #
      # Initiates a call and notifies all conversation members via WebSocket.
      # The call starts in "ringing" status (everyone's phone rings).
      #
      # TODO: def create
      #         call = @conversation.call_sessions.build(
      #           call_params.merge(initiator: current_user, status: :ringing)
      #         )
      #         authorize call
      #         if call.save
      #           broadcast_incoming_call(call)
      #           render json: CallSessionBlueprint.render(call), status: :created
      #         else
      #           render json: { errors: call.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def create
        call = @conversation.call_sessions.build(
          call_params.merge(initiator: current_user, status: :ringing)
        )
        authorize call
        if call.save
          # Add the initiator as a participant immediately so CallChannel#participant?
          # passes the guard for them from the moment the call exists.
          CallParticipant.create!(call_session: call, user: current_user)
          broadcast_incoming_call(call)
          render json: { data: CallSessionBlueprint.render_as_hash(call) }, status: :created
        else
          render json: { errors: call.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ─── accept ─────────────────────────────────────────────────────────────
      # PUT /api/v1/conversations/:conversation_id/calls/:id/accept
      #
      # The callee accepts the incoming call. Three things happen:
      #   1. A CallParticipant record is created for current_user (joined_at = now).
      #   2. The call transitions ringing → active and started_at is stamped.
      #   3. A call_accepted event is broadcast to the call stream.
      #
      # After this returns 200, the frontend can safely subscribe to CallChannel
      # because participant?(call) now passes for this user. The initiator then
      # sends the WebRTC SDP offer over that channel to complete the handshake.
      #
      # find_or_create_by! guards against double-tapping Accept without raising —
      # the DB unique index on [call_session_id, user_id] is the final safety net.
      def accept
        call = @conversation.call_sessions.find(params[:id])
        authorize call

        # with_lock acquires a row-level advisory lock (SELECT … FOR UPDATE) so
        # the guard check + status write are atomic — prevents two concurrent
        # "accept" requests from both passing the ringing? guard before either
        # commits (TOCTOU race).
        call.with_lock do
          unless call.ringing?
            return render json: { error: "Call is no longer ringing" }, status: :unprocessable_entity
          end


          CallParticipant.find_or_create_by!(call_session: call, user: current_user)

          # Stamp started_at only once — in a group call a second participant
          # accepting should not overwrite the timestamp set by the first.
          call.update!(status: :active, started_at: call.started_at || Time.current)
        end

        ActionCable.server.broadcast("call_#{call.id}", {
          type: "call_accepted",
          call_session_id: call.id,
          accepted_by: UserBlueprint.render_as_hash(current_user, view: :public)
        })

        render json: CallSessionBlueprint.render(call)
      end

      # ─── decline ────────────────────────────────────────────────────────────
      # PUT /api/v1/conversations/:conversation_id/calls/:id/decline
      #
      # The callee rejects the incoming call. Broadcasts to two streams:
      #   - "call_<id>"           → wakes the initiator's CallChannel subscription
      #   - "conversation_<id>"   → dismisses the ringing banner for all members
      def decline
        call = @conversation.call_sessions.find(params[:id])
        authorize call

        # Same TOCTOU guard as accept — lock the row so two concurrent decline
        # requests cannot both pass the ringing? check before either commits.
        call.with_lock do
          unless call.ringing?
            return render json: { error: "Call is no longer ringing" }, status: :unprocessable_entity
          end

          call.update!(status: :declined)
        end

        payload = {
          type: "call_declined",
          call_session_id: call.id,
          declined_by: UserBlueprint.render_as_hash(current_user, view: :public)
        }
        ActionCable.server.broadcast("call_#{call.id}", payload)
        ActionCable.server.broadcast("conversation_#{@conversation.id}", payload)

        render json: CallSessionBlueprint.render(call)
      end

      # ─── active ─────────────────────────────────────────────────────────────
      # GET /api/v1/conversations/:conversation_id/calls/active
      # Returns the currently active call, if any.
      # Used when a user opens a conversation mid-call ("join late" flow).
      # Returns 404 if no active call — client hides the "join" button.
      #
      # TODO: def active
      #         call = @conversation.call_sessions.find_by!(status: :active)
      #         render json: CallSessionBlueprint.render(call, view: :with_participants)
      #       end
      def active
        call = @conversation.call_sessions.find_by!(status: :active)
        render json: CallSessionBlueprint.render(call, view: :with_participants)
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/conversations/:conversation_id/calls/:id
      # Ends the call — sets status to :ended and broadcasts call_ended to all.
      # Pundit: only the initiator can end the call.
      #
      # TODO: def destroy
      #         call = @conversation.call_sessions.find(params[:id])
      #         authorize call
      #         call.update!(status: :ended)
      #         ActionCable.server.broadcast("call_#{call.id}", { type: "call_ended", call_session_id: call.id })
      #         render json: { message: "Call ended" }
      #       end
      def destroy
        call = @conversation.call_sessions.find(params[:id])
        authorize call
        call.update!(status: :ended)
        ActionCable.server.broadcast("call_#{call.id}", { type: "call_ended", call_session_id: call.id })
        render json: { message: "Call ended" }
      end

      private

      # TODO: def set_conversation
      #         @conversation = current_user.conversations.find(params[:conversation_id])
      #       end
      def set_conversation
        @conversation = current_user.conversations.find(params[:conversation_id])
      end

      # TODO: def call_params
      #         params.require(:call).permit(:call_type)
      #       end
      def call_params
        params.require(:call).permit(:call_type)
      end

      # Broadcasts an incoming_call event to ALL members of the conversation.
      # Each member sees the ringing notification regardless of whether they're
      # subscribed to the CallChannel yet — they subscribe when they answer.
      #
      # TODO: def broadcast_incoming_call(call)
      #         ActionCable.server.broadcast(
      #           "conversation_#{@conversation.id}",
      #           {
      #             type: "incoming_call",
      #             call_session_id: call.id,
      #             caller: UserBlueprint.render_as_hash(current_user, view: :public),
      #             call_type: call.call_type,
      #             conversation_id: @conversation.id
      #           }
      #         )
      #       end
      # Broadcasts incoming_call to each OTHER member's personal CallChannel stream.
      # Personal streams ("calls_user_<id>") are always active for authenticated users
      # regardless of which page they are on — unlike conversation streams which only
      # exist while a conversation is open. This guarantees notification delivery.
      def broadcast_incoming_call(call)
        payload = {
          type: "incoming_call",
          call_session_id: call.id,
          caller: UserBlueprint.render_as_hash(current_user, view: :public),
          call_type: call.call_type,
          conversation_id: @conversation.id
        }

        # pluck avoids loading full User objects — we only need the IDs
        @conversation.members.where.not(id: current_user.id).pluck(:id).each do |member_id|
          ActionCable.server.broadcast("calls_user_#{member_id}", payload)
        end
      end
    end
  end
end
