(function() {
  var $form_values_present, $present;

  $('.group_assignments').ready(function() {
    return $('form').on('change keyup', function() {
      var $submit_button;
      $submit_button = $('#group_assignment_submit');
      if ($form_values_present()) {
        return $submit_button.prop('disabled', false);
      } else {
        return $submit_button.prop('disabled', true);
      }
    });
  });

  $form_values_present = function() {
    return $present('group_assignment_title') && ($present('grouping_title') || $present('group_assignment_grouping_id'));
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
