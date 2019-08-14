# frozen_string_literal: true

class FormView < ViewModel
  attr_reader :subject

  def errors_for?(field)
    subject.errors[field].present?
  end

  def error_message_for(field)
    subject.errors.full_messages_for(field).join(", ")
  end

  def form_class_for(field)
    "form-group#{errors_for?(field) ? ' errored primer-new' : ''}"
  end

  def error_message_for_object(object)
    object.errors.full_messages.join(", ")
  end

  def errors_for_object?(object)
    object&.errors.present?
  end
end
