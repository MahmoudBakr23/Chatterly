module Api
  module V1
    class MessagesController < BaseController
      before_action :set_conversation

      # ─── index ──────────────────────────────────────────────────────────────
      # GET /api/v1/conversations/:conversation_id/messages
      # Returns last 50 visible messages. Supports cursor pagination via ?before_id=.
      #
      # Why cursor pagination instead of page/offset?
      #   With millions of rows, OFFSET scans all skipped rows (slow).
      #   WHERE id < before_id uses the index directly — O(log n) regardless of depth.
      #
      # TODO: def index
      #         messages = @conversation.messages.visible
      #                      .includes(:user, :reactions)
      #                      .order(created_at: :desc)
      #         messages = messages.where("id < ?", params[:before_id]) if params[:before_id]
      #         messages = messages.limit(params.fetch(:limit, 50))
      #         render json: MessageBlueprint.render(messages.reverse)
      #       end
      def index
      end

      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/conversations/:conversation_id/messages
      # Saves the message, then broadcasts it to all WebSocket subscribers.
      # The WebSocket broadcast is the real-time path — REST is the authoritative write.
      #
      # TODO: def create
      #         message = @conversation.messages.build(message_params.merge(user: current_user))
      #         authorize message
      #         if message.save
      #           ActionCable.server.broadcast(
      #             "conversation_#{@conversation.id}",
      #             { type: "new_message", message: MessageBlueprint.render_as_hash(message) }
      #           )
      #           render json: MessageBlueprint.render(message), status: :created
      #         else
      #           render json: { errors: message.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def create
      end

      # ─── update ─────────────────────────────────────────────────────────────
      # PATCH /api/v1/conversations/:conversation_id/messages/:id
      # Edits content and sets edited_at. Pundit: author only.
      #
      # TODO: def update
      #         message = @conversation.messages.find(params[:id])
      #         authorize message
      #         if message.update(message_params.merge(edited_at: Time.current))
      #           ActionCable.server.broadcast(
      #             "conversation_#{@conversation.id}",
      #             { type: "message_edited", message: MessageBlueprint.render_as_hash(message) }
      #           )
      #           render json: MessageBlueprint.render(message)
      #         else
      #           render json: { errors: message.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def update
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/conversations/:conversation_id/messages/:id
      # Soft deletes (sets deleted_at). Content is NOT permanently removed.
      # The WebSocket broadcasts { type: "message_deleted", message_id: } so
      # all clients can swap the bubble for "[Message deleted]".
      # Pundit: author or conversation admin.
      #
      # TODO: def destroy
      #         message = @conversation.messages.find(params[:id])
      #         authorize message
      #         message.soft_delete!
      #         ActionCable.server.broadcast(
      #           "conversation_#{@conversation.id}",
      #           { type: "message_deleted", message_id: message.id }
      #         )
      #         render json: { message: "Message deleted" }
      #       end
      def destroy
      end

      private

      # Loads the conversation, verifying membership at the same time.
      # Using current_user.conversations (not Conversation.find) means non-members
      # get 404 (record not found in their scope) rather than a separate auth check.
      #
      # TODO: def set_conversation
      #         @conversation = current_user.conversations.find(params[:conversation_id])
      #       end
      def set_conversation
      end

      # TODO: def message_params
      #         params.require(:message).permit(:content, :message_type, :parent_message_id)
      #       end
      def message_params
      end
    end
  end
end
