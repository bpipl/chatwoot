# frozen_string_literal: true

# Extends conversation visibility to include conversations where the user
# is a participant, even if they don't have inbox access.
# Also fixes the enterprise custom role clash where 'conversation_participating_manage'
# filters to assigned_to(user) only, excluding participant conversations.
module Custom::Conversations::PermissionFilterService
  def perform
    result = super

    # After enterprise filtering, ensure participant conversations are always included
    # for agents with custom roles. Without this, the enterprise filter for
    # 'conversation_participating_manage' narrows to assigned_to(user) only.
    return result if user_role == 'administrator'

    participant_conversation_ids = ConversationParticipant
      .where(user_id: user.id, account_id: account.id)
      .select(:conversation_id)

    participant_convos = conversations.where(id: participant_conversation_ids)

    # Union the enterprise-filtered result with participant conversations
    conversations
      .where(id: result.select(:id))
      .or(conversations.where(id: participant_convos.select(:id)))
  end

  private

  def accessible_conversations
    inbox_conversations = super
    participant_conversation_ids = ConversationParticipant
      .where(user_id: user.id, account_id: account.id)
      .select(:conversation_id)

    conversations
      .where(id: inbox_conversations.select(:id))
      .or(conversations.where(id: participant_conversation_ids))
  end
end
