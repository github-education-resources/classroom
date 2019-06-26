(function() {
  var debounce, ready;

  debounce = (function() {
    var timer;
    timer = 0;
    return function(callback, ms) {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(callback, ms);
    };
  })();

  ready = function() {
    return $('#js-search-form').on('keyup', function() {
      var $this, formData;
      $this = $(this);
      formData = $(this).find('input[name!=utf8]').serialize();
      history.replaceState(null, '', '?' + formData);

      debounce(function() { 
        $this.one('ajax:success', function(e, data, status, xhr) {
          return $('#js-search-results').html(xhr.responseText);
        });
        
        $this.submit();
      }, 300);
    });
  };

  $(document).ready(ready);
}).call(this);
