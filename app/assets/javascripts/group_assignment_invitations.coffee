$('.group_assignment_invitations.show').ready ->
  $add_button = $('#add_new_group')
  $new_group_form = $('form#new_group_form')

  $new_group_form.on('change keyup', ->
    if $('#group_title').val().length != 0
      $add_button.prop('disabled', false)
    else
      $add_button.prop('disabled', true)
  )

  $new_group_form.on('submit', ->
    $(this).addClass('loading')
  )
