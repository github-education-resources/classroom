$('.assignment_invitations.show').ready ->
  $assignmentInvitationStatus = $('#assignment-invitation-status')
  key = $assignmentInvitationStatus.data('invitationKey')

  $invitation_request = $.ajax(
    url: "/assignment_invitations/#{key}/accept_invitation"
    method: 'GET'
    dataType: 'JSON'
  )

  $invitation_request.done (response) ->
    $assignmentInvitationStatus.html("<h1>#{response.message}</h1>")

  $invitation_request.fail (response) ->
    $assignmentInvitationStatus.html("<h1>#{response.message}</h1>")

  $invitation_request.always ->
    $('#assignment-invitation-status').removeClass('loading')

  return
