(function() {
  var delay, ready;

  delay = (function() {
    var timer;
    timer = 0;
    return function(callback, ms) {
      clearTimeout(timer);
      timer = setTimeout(callback, ms);
    };
  })();

  ready = function() {
    return $('#js-search-form').on('change keyup', function() {
      var $this, formData;
      $this = $(this);
      formData = $(this).serialize();
      history.replaceState(null, '', "?" + formData);
      return delay((function() {
        $this.submit();
        return $this.on('ajax:success', function(e, data, status, xhr) {
          return $('#js-search-results').html(xhr.responseText);
        });
      }), 200);
    });
  };

  $(document).ready(ready);
}).call(this);
