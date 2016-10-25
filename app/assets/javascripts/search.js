(function() {
  var ready;

  ready = function() {
    return $('#js-search-form').on('submit', function() {
      var $this, formData;

      $this = $(this);
      formData = $(this).serialize();

      return $this.on('ajax:success', function(e, data, status, xhr) {
        return $('#js-search-results').html(xhr.responseText);
      });
    });
  };

  $(document).ready(ready);
}).call(this);
