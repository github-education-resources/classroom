ready = ->
  $('.js-navigation').on('click', -> $('.loading-indicator').show())

$(document).ready(ready)
$(document).on('page:load', ready)
