# frozen_string_literal: true

# Extends conversation visibility to include conversations where the user
# is a participant, even if they don't have inbox access.
# This enables selective sharing of conversations from private inboxes.
module Custom::Conversations::PermissionFilterService
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
