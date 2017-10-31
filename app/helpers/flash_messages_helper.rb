# frozen_string_literal: true

module FlashMessagesHelper
  def primer_class_for(flash_type)
    { alert: "flash-error", error: "flash-error", notice: "flash-warn" }[flash_type.to_sym] || ""
  end
end
