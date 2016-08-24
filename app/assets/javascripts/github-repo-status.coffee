ready = ->
  $.each($('.js-github-repo-latest-release-container'), (_, element) ->
    $container = $(element)
    $.get $container.data('latest-release-url'), (data) ->
      $container.html(data)
    )

$(document).ready(ready)
