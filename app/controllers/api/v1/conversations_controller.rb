module Api
  module V1
    class ConversationsController < BaseController
      before_action :set_conversation, only: %i[show destroy]
      # ─── index ──────────────────────────────────────────────────────────────
      # GET /api/v1/conversations
      # Returns every conversation the current user is a member of.
      # current_user.conversations comes from has_many :through :conversation_members.
      def index
        conversations = current_user.conversations.includes(:members)
        render json: { data: ConversationBlueprint.render_as_hash(conversations, view: :with_members) }
      end

      # ─── show ───────────────────────────────────────────────────────────────
      # GET /api/v1/conversations/:id
      # Returns a single conversation with its member list.
      # Pundit guards this — non-members get 403, not 404, to avoid leaking existence.
      def show
        authorize @conversation
        render json: { data: ConversationBlueprint.render_as_hash(@conversation, view: :with_members) }
      end

      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/conversations
      # Creates a channel, group DM, or direct message conversation.
      #
      # For DMs, member_ids in the params automatically adds the other user.
      # The creator is always added as a member with role: "admin".
      def create
        conversation = current_user.created_conversations.build(conversation_params)
        authorize conversation
        if conversation.save
          conversation.members << current_user
          add_members(conversation)
          # Notify every member except the creator so their sidebar updates in real
          # time without a page refresh. The creator already has the conversation via
          # the REST response (addConversation in the store). The store's addConversation
          # action deduplicates by id, so broadcasting to everyone (including creator)
          # is also safe — we skip them here only to avoid an unnecessary broadcast.
          broadcast_new_conversation(conversation)
          render json: { data: ConversationBlueprint.render_as_hash(conversation, view: :with_members) }, status: :created
        else
          render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/conversations/:id
      # Pundit: only the creator or an admin member can delete.
      def destroy
        authorize @conversation
        @conversation.destroy
        render json: { message: "Conversation deleted" }
      end

      private

      def conversation_params
        params.require(:conversation).permit(:name, :description, :conversation_type)
      end

      # Adds extra members from member_ids param (used for DMs and group creation).
      # Silently skips invalid IDs — no error raised for unknown users.
      #
      # Broadcasts the full conversation payload to every member's personal UserChannel
      # stream so their sidebar shows the new conversation in real time.
      # Skips the creator — they already have it via the REST response.
      def broadcast_new_conversation(conversation)
        payload = {
          type: "new_conversation",
          conversation: ConversationBlueprint.render_as_hash(conversation, view: :with_members)
        }
        conversation.members.where.not(id: current_user.id).pluck(:id).each do |member_id|
          ActionCable.server.broadcast("user_#{member_id}", payload)
        end
      end

      def add_members(conversation)
        # member_ids is NOT a Conversation column, so Rails wrap_parameters leaves it
        # at the top level of params (not nested under :conversation). Reading it from
        # params[:member_ids] directly is the correct location after wrap_parameters runs.
        ids = params[:member_ids]
        return unless ids.present?
        users = User.where(id: ids)
        conversation.members << users
      end

      def set_conversation
        @conversation = Conversation.find(params[:id])
      end
    end
  end
end
