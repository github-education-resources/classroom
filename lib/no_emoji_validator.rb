# frozen_string_literal: true

class NoEmojiValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if value.match(Unicode::Emoji::REGEX_VALID).nil?
    record.errors.add(attribute, "#{attribute} is not allowed to have emojis.")
  end
end

ActiveModel::Validations::NoEmojiValidator = NoEmojiValidator
