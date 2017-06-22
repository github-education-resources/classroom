# frozen_string_literal: true

class FormView < ViewModel
  attr_reader :subject, :organization

  def errors_for?(field)
    subject.errors[field].present?
  end

  def error_message_for(field)
    subject.errors.full_messages_for(field).join(', ')
  end

  def form_class_for(field)
    "form#{errors_for?(field) ? ' errored primer-new' : ''}"
  end

  def private_repos_available?
    plan = organization.plan

    plan[:owned_private_repos] < plan[:private_repos]
  end
end
