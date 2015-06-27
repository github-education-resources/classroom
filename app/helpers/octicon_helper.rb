module OcticonHelper
  # Public: Mega Octicon View Helper
  #
  # code - The String that sets the octicon
  #
  # Examples
  #
  #  mega_octicon('mark-github')
  #  # => "<span class=\"mega-octicon mega-octicon-mark-github\"></span>"
  #
  # Returns the <span> tag with the mega-octicon classes as a String
  def mega_octicon(code)
    content_tag :span, '', class: "mega-octicon octicon-#{code.to_s.dasherize}"
  end

  # Public: Octicon View Helper
  #
  # code - The String that sets the octicon
  #
  # Examples
  #
  #  octicon('mark-github')
  #  # => "<span class=\"octicon octicon-mark-github\"></span>"
  #
  # Returns the <span> tag with the octicon classes as a String
  def octicon(code)
    content_tag :span, '', class: "octicon octicon-#{code.to_s.dasherize}"
  end
end
