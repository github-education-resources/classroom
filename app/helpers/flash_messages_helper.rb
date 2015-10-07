module FlashMessagesHelper
  # Public: Get the corresponding css class for the Rails
  # flash type in question.
  #
  # flash_type - The Flash message in question
  #
  # Returns the proper css flash class as a String
  def primer_class_for(flash_type)
    { alert: 'flash-error', error: 'flash-error', notice: 'flash-warn' }[flash_type.to_sym] || ''
  end
end
