$('.assignment_invitations.identifier, .group_assignment_invitations.identifier').ready ->
  $('form').on('change keyup', ->
    $('.js-form-submit').prop('disabled', $('#student_identifier_value').val().length == 0)
  )
