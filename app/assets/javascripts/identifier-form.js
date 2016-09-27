(function() {
  $('.assignment_invitations.identifier, .group_assignment_invitations.identifier').ready(function() {
    return $('form').on('change keyup', function() {
      return $('.js-form-submit').prop('disabled', $('#student_identifier_value').val().length === 0);
    });
  });
}).call(this);
