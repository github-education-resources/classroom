(function() {
  var ready;

  ready = function() {
    $('.js-normalize-submit').on('change keyup', function() {
      var resourceName;
      resourceName = $(this).closest('form').attr('data-name');
      if ($('.js-input-block').val() === resourceName) {
        return $('.js-submit').prop('disabled', false);
      } else {
        return $('.js-submit').prop('disabled', true);
      }
    });
    return $('.remodal-close').on('click', function() {
      return $('.js-input-block').val('');
    });
  };

  $(document).ready(ready);
}).call(this);
