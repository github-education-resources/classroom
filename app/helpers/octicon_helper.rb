module OcticonHelper
  # Public: Get a mega-oction
  #
  # code - The String which contains the octicon type
  #
  # Returns a String which is a <span> and the octicon
  def mega_octicon(code)
    content_tag :span, '', class: "mega-octicon octicon-#{code.to_s.dasherize}"
  end

  # Public: Get a oction
  #
  # code - The String which contains the octicon type
  #
  # Returns a String which is a <span> and the octicon
  def octicon(code)
    content_tag :span, '', class: "octicon octicon-#{code.to_s.dasherize}"
  end
end
