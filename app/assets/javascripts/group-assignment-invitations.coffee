$('.group_assignment_invitations.show').ready ->
  $form = $('form')

  $form.on('change keyup', ->
    $submitButton = $('.js-submit-button')

    if $form_values_present()
      $submitButton.prop('disabled', false)
    else
      $submitButton.prop('disabled', true)
  )

  $form.on('submit', -> $('body').addClass('loading'))

$form_values_present = () ->
  $present('group_title') || $present('group_id')

$present = (id) ->
  $el = $("##{id}")

  if $el.length != 0
    return $el.val().length != 0

  false
