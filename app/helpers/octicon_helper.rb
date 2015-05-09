module OcticonHelper
  def mega_octicon(code)
    content_tag :span, '', :class => "mega-octicon octicon-#{code.to_s.dasherize}"
  end

  def octicon(code)
    content_tag :span, '', :class => "octicon octicon-#{code.to_s.dasherize}"
  end
end
