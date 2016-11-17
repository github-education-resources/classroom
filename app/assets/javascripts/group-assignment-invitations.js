(function() {
  var $form_values_present, $present;

  $('.group_assignment_invitations.show').ready(function() {
    var $form;
    $form = $('form');
    return $('form').on('change keyup', function() {
      var $submitButton;
      $submitButton = $('.js-form-submit');
      if ($form_values_present()) {
        return $submitButton.prop('disabled', false);
      } else {
        return $submitButton.prop('disabled', true);
      }
    });
  });

  $form_values_present = function() {
    return $present('group_title') || $present('group_id');
  };

  $present = function(id) {
    var $el;
    $el = $("#" + id);
    if ($el.length !== 0) {
      return $el.val().length !== 0;
    }
    return false;
  };
}).call(this);
