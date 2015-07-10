$('.group_assignments').ready ->
  $('form').on('change keyup',  ->
    $submit_button = $('#group_assignment_submit')

    if $form_values_present()
      $submit_button.prop('disabled', false)
    else
      $submit_button.prop('disabled', true)
  )

$form_values_present = () ->
  $present('group_assignment_title') && ($present('grouping_title') || $present('group_assignment_grouping_id'))

$present = (id) ->
  $el = $("##{id}")

  if $el.length != 0
    return $el.val().length != 0

  false
