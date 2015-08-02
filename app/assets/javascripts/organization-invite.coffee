$('.organizations.invite').ready ->
  $form         = $('form')
  $inviteButton = $('form').find('[type=submit]')

  $form.on('change keyup', ->
    disabled = true

    $('.js-user-invitation-form').each ->
      $checkbox  = $(this).children().closest('label').find('[type=checkbox]')
      $emailForm = $(this).children().closest('input')

      if $checkbox.prop('checked') && $emailForm.val() != ''
        disabled = false

    $inviteButton.attr('disabled', disabled)
  )

  $form.on('submit', -> $('form').addClass('loading'))
