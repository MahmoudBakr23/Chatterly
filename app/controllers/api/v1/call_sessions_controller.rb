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
          broadcast_incoming_call(call)
          render json: CallSessionBlueprint.render(call), status: :created
        else
          render json: { errors: call.errors.full_messages }, status: :unprocessable_entity
        end
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
      def broadcast_incoming_call(call)
        ActionCable.server.broadcast(
          "conversation_#{@conversation.id}",
          {
            type: "incoming_call",
            call_session_id: call.id,
            caller: UserBlueprint.render_as_hash(current_user, view: :public),
            call_type: call.call_type,
            conversation_id: @conversation.id
          }
        )
      end
    end
  end
end
