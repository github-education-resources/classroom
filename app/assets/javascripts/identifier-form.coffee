$('.assignment_invitations.identifier, .group_assignment_invitations.identifier').ready ->
  $form = $('form')

  $('form').on('change keyup', ->
    $submitButton = $('.js-form-submit')

    if $form_values_present()
      $submitButton.prop('disabled', false)
    else
      $submitButton.prop('disabled', true)
  )

$form_values_present = () ->
  $present('student_identifier')

$present = (id) ->
  $el = $("##{id}")

  if $el.length != 0
    return $el.val().length != 0

  false
