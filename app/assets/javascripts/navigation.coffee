ready = ->
  $('.js-navigation').on('click', (event) ->
    if (event.ctrlKey or # New tab (windows)
    event.shiftKey or # New window
    event.metaKey or # New tab (mac)
    (event.button and event.button == 1) # New tab (middle click)
    )
      return
    return $('.loading-indicator').show())

$(document).ready(ready)
$(document).on('page:load', ready)
