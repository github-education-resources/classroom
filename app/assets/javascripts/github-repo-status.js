(function() {
  $.each($('.js-github-repo-status-container'), function(name, element) {
    $container = $(element);
    $.get($container.data('status-url'), function(data) { $container.html(data) });
  });
}).call(this);
