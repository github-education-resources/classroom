(function() {
  var $title_present, $title_blacklisted, $present;

  var $title_blacklist = [
    'new',
    'edit'
  ]

  $('.assignments').ready(function() {
    return $('form').on('change keyup', function() {
      var $submit_button;
      $submit_button = $('#assignment_submit');

      if ($title_present() && !$title_blacklisted()) {
        return $submit_button.prop('disabled', false);
      } else {
        return $submit_button.prop('disabled', true);
      }
    });
  });

  $title_present = function() {
    return $present('assignment_title');
  };

  $title_blacklisted = function() {
    var $title = $('#assignment_title').val();
    console.log($title);

    return ($.inArray($title, $title_blacklist) !== -1)
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
