module InvitationsHelper
  # rubocop:disable Lint/Eval
  def invitation_url(base_url, invitation)
    invitation_path = eval("#{invitation.class.name.underscore}_path('#{invitation.key}')")
    invitation_url  = "#{base_url}#{invitation_path}"

    return shorten_url(invitation_url) if Rails.env.production?
    invitation_url
  end
  # rubocop:enable Lint/Eval

  def shorten_url(url)
    Bitly.client.shorten(url).short_url
  end
end
