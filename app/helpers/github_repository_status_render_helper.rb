# frozen_string_literal: true
module GitHubRepositoryStatusRenderHelper
  def tooltip_text_for_build_status(status)
    case status
    when 'pending'
      'Build is still in progress'
    when 'success'
      'Build completed successfully'
    when 'failure'
      'Build failed'
    end
  end

  def octicon_name_for_build_status(status)
    case status
    when 'pending'
      'primitive-dot'
    when 'success'
      'check'
    when 'failure'
      'x'
    end
  end
end
