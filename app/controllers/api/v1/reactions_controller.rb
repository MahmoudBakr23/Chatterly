module Api
  module V1
    class ReactionsController < BaseController
      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/reactions
      # Body: { reaction: { message_id: 1, emoji: "👍" } }
      #
      # message_created_at must be looked up from the message — it is required
      # to find the correct partition when inserting into the reactions table.
      # (See reactions migration — message_created_at is for FK partition lookup.)
      #
      # TODO: def create
      #         message = Message.find(params[:reaction][:message_id])
      #         reaction = message.reactions.build(
      #           reaction_params.merge(
      #             user: current_user,
      #             message_created_at: message.created_at
      #           )
      #         )
      #         authorize reaction
      #         if reaction.save
      #           ActionCable.server.broadcast(
      #             "conversation_#{message.conversation_id}",
      #             { type: "reaction_added", reaction: ReactionBlueprint.render_as_hash(reaction) }
      #           )
      #           render json: ReactionBlueprint.render(reaction), status: :created
      #         else
      #           render json: { errors: reaction.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def create
        message = Message.find(params[:reaction][:message_id])
        reaction = message.reactions.build(
          reaction_params.merge(
            user: current_user,
            message_created_at: message.created_at
          )
        )
        authorize reaction
        if reaction.save
          ActionCable.server.broadcast(
            "conversation_#{message.conversation_id}",
            { type: "reaction_added", reaction: ReactionBlueprint.render_as_hash(reaction) }
          )
          render json: ReactionBlueprint.render(reaction), status: :created
        else
          render json: { errors: reaction.errors.full_messages },
                  status: :unprocessable_entity
        end
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/reactions/:id
      # Pundit: only the user who added the reaction can remove it.
      #
      # TODO: def destroy
      #         reaction = Reaction.find(params[:id])
      #         authorize reaction
      #         reaction.destroy
      #         ActionCable.server.broadcast(
      #           "conversation_#{reaction.message.conversation_id}",
      #           { type: "reaction_removed", reaction_id: reaction.id, message_id: reaction.message_id }
      #         )
      #         render json: { message: "Reaction removed" }
      #       end
      def destroy
        reaction = Reaction.find(params[:id])
        authorize reaction
        reaction.destroy
        ActionCable.server.broadcast(
          "conversation_#{reaction.message.conversation_id}",
          { type: "reaction_removed", reaction_id: reaction.id, message_id: reaction.message_id }
        )
        render json: { message: "Reaction removed" }
      end

      private

      # TODO: def reaction_params
      #         params.require(:reaction).permit(:message_id, :emoji)
      #       end
      def reaction_params
        params.require(:reaction).permit(:message_id, :emoji)
      end
    end
  end
end
