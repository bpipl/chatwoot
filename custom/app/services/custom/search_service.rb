# frozen_string_literal: true

# Fixes the contact search leak: by default, Chatwoot's SearchService
# returns ALL contacts in the account regardless of inbox access.
# This override scopes contact search results to only show contacts
# that have conversations in the agent's accessible inboxes or in
# conversations shared with them (via participants).
module Custom::SearchService
  private

  def filter_contacts
    return super if should_skip_inbox_filtering?

    # Contacts from conversations in accessible inboxes
    inbox_contact_ids = current_account.conversations
      .where(inbox_id: accessable_inbox_ids)
      .select(:contact_id)

    # Contacts from conversations shared with this user (via participants)
    shared_contact_ids = current_account.conversations
      .where(
        id: ConversationParticipant
              .where(user_id: current_user.id, account_id: current_account.id)
              .select(:conversation_id)
      )
      .select(:contact_id)

    contacts_query = current_account.contacts
      .where(id: inbox_contact_ids)
      .or(current_account.contacts.where(id: shared_contact_ids))
      .where(
        "name ILIKE :search OR email ILIKE :search OR phone_number ILIKE :search OR identifier ILIKE :search",
        search: "%#{search_query}%"
      )

    if current_account.feature_enabled?('advanced_search')
      contacts_query = apply_time_filter(contacts_query, 'last_activity_at')
    end

    @contacts = contacts_query
      .resolved_contacts(use_crm_v2: current_account.feature_enabled?('crm_v2'))
      .order_on_last_activity_at('desc')
      .page(params[:page])
      .per(15)
  end
end
