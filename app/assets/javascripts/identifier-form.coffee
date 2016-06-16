('.assignment_invitations.identifier, .group_assignment_invitations.identifier').ready ->
  $('form').on('change keyup', ->
    console.log($('student_identifier').length)
    $('.js-form-submit').prop('disabled', $('#student_identifier').val().length == 0)
  )
