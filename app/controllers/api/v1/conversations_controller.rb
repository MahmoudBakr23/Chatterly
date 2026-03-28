module Api
  module V1
    class ConversationsController < BaseController
      before_action :set_conversation, only: %i[show destroy]
      # ─── index ──────────────────────────────────────────────────────────────
      # GET /api/v1/conversations
      # Returns every conversation the current user is a member of.
      # current_user.conversations comes from has_many :through :conversation_members.
      #
      # TODO: def index
      #         conversations = current_user.conversations
      #         render json: ConversationBlueprint.render(conversations)
      #       end
      def index
        conversations = current_user.conversations.includes(:members)
        render json: { data: ConversationBlueprint.render_as_hash(conversations, view: :with_members) }
      end

      # ─── show ───────────────────────────────────────────────────────────────
      # GET /api/v1/conversations/:id
      # Returns a single conversation with its member list.
      # Pundit guards this — non-members get 403, not 404, to avoid leaking existence.
      #
      # TODO: def show
      #         conversation = Conversation.find(params[:id])
      #         authorize conversation
      #         render json: ConversationBlueprint.render(conversation, view: :with_members)
      #       end
      def show
        authorize @conversation
        render json: ConversationBlueprint.render(@conversation, view: :with_members)
      end

      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/conversations
      # Creates a channel, group DM, or direct message conversation.
      #
      # For DMs, member_ids in the params automatically adds the other user.
      # The creator is always added as a member with role: "admin".
      #
      # TODO: def create
      #         conversation = current_user.created_conversations.build(conversation_params)
      #         authorize conversation
      #         if conversation.save
      #           conversation.members << current_user  # creator is always a member
      #           add_members(conversation)             # add member_ids if provided (DM/group)
      #           render json: ConversationBlueprint.render(conversation, view: :with_members),
      #                  status: :created
      #         else
      #           render json: { errors: conversation.errors.full_messages },
      #                  status: :unprocessable_entity
      #         end
      #       end
      def create
        conversation = current_user.created_conversations.build(conversation_params)
        authorize conversation
        if conversation.save
          conversation.members << current_user
          add_members(conversation)
          render json: ConversationBlueprint.render(conversation, view: :with_members), status: :created
        else
          render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/conversations/:id
      # Pundit: only the creator or an admin member can delete.
      #
      # TODO: def destroy
      #         conversation = Conversation.find(params[:id])
      #         authorize conversation
      #         conversation.destroy
      #         render json: { message: "Conversation deleted" }
      #       end
      def destroy
        authorize @conversation
        @conversation.destroy
        render json: { message: "Conversation deleted" }
      end

      private

      # TODO: def conversation_params
      #         params.require(:conversation).permit(:name, :description, :conversation_type)
      #       end
      def conversation_params
        params.require(:conversation).permit(:name, :description, :conversation_type)
      end

      # Adds extra members from member_ids param (used for DMs and group creation).
      # Silently skips invalid IDs — no error raised for unknown users.
      #
      # TODO: def add_members(conversation)
      #         return unless params[:conversation][:member_ids].present?
      #         users = User.where(id: params[:conversation][:member_ids])
      #         conversation.members << users
      #       end
      def add_members(conversation)
        return unless params[:conversation][:member_ids].present?
        users = User.where(id: params[:conversation][:member_ids])
        conversation.members << users
      end

      def set_conversation
        @conversation = Conversation.find(params[:id])
      end
    end
  end
end
