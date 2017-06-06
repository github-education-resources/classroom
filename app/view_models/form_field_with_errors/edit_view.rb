# frozen_string_literal: true

module FormFieldWithErrors
  class EditView < ViewModel
    attr_reader :object, :field

    def has_errors?
      object.errors[field].present?
    end

    def form_class
      "form#{has_errors? ? ' errored' : ''}"
    end

    def error_message
      object.errors.full_messages_for(field).join(', ')
    end
  end
end
