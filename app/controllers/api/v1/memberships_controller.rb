module Api
  module V1
    # MembershipsController manages who belongs to a conversation.
    # Nested under conversations: /api/v1/conversations/:conversation_id/memberships
    class MembershipsController < BaseController
      before_action :set_conversation

      # ─── create ─────────────────────────────────────────────────────────────
      # POST /api/v1/conversations/:conversation_id/memberships
      # Body: { user_id: 3 }
      # Pundit: only an admin member of the conversation can add others.
      def create
        authorize @conversation, :manage_members?
        user = User.find(params[:user_id])
        membership = @conversation.conversation_members.build(user: user)
        if membership.save
          ActionCable.server.broadcast(
            "conversation_#{@conversation.id}",
            { type: "member_joined", user: UserBlueprint.render_as_hash(user, view: :public) }
          )
          render json: { message: "Member added" }, status: :created
        else
          render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # ─── destroy ────────────────────────────────────────────────────────────
      # DELETE /api/v1/conversations/:conversation_id/memberships/:id
      # :id is the user_id being removed (or current_user.id to leave).
      # Pundit: admin can remove anyone; regular members can only remove themselves.
      def destroy
        membership = @conversation.conversation_members.find_by!(user_id: params[:id])
        authorize @conversation, :manage_members? unless membership.user_id == current_user.id
        membership.destroy
        ActionCable.server.broadcast(
          "conversation_#{@conversation.id}",
          { type: "member_left", user_id: membership.user_id }
        )
        render json: { message: "Left conversation" }
      end

      private

      def set_conversation
        @conversation = current_user.conversations.find(params[:conversation_id])
      end
    end
  end
end
