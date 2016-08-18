ready = ->
  $.each($('.js-github-repo-status-container'), (_, element) ->
    $container = $(element)
    $.get $container.data('status-url'), (data) ->
      $container.html(data)
  )

$(document).ready(ready)
