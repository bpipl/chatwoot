# frozen_string_literal: true

# Extends conversation access to include participants.
# The base class already has a `participant?` method but doesn't use it
# in `agent_can_view_conversation?`. This module adds it.
module Custom::ConversationPolicy
  private

  def agent_can_view_conversation?
    super || participant?
  end
end
