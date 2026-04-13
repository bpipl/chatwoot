# frozen_string_literal: true

# Patches for models that don't call prepend_mod and thus can't be extended
# via the standard Custom:: module mechanism.

Rails.application.config.after_initialize do
  # Patch ConversationParticipant to remove inbox access validation.
  # This allows admins to add participants from any inbox, enabling
  # selective conversation sharing from private inboxes.
  ConversationParticipant.class_eval do
    private

    def ensure_inbox_access
      # No-op: allow cross-inbox participants for selective sharing.
      # Original: errors.add(:user, 'must have inbox access') if conversation && conversation.inbox.assignable_agents.exclude?(user)
    end
  end

  # Enable enterprise features on self-hosted installation.
  # Sets the pricing plan to 'enterprise' so enterprise-gated features
  # (custom roles, custom branding, agent capacity) are unlocked.
  if ChatwootApp.enterprise?
    config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
    config.update(value: 'enterprise') if config.value.blank? || config.value == 'community'

    config_qty = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    config_qty.update(value: 100) if config_qty.value.blank? || config_qty.value.to_i.zero?
  end
end
