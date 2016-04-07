ready = ->
  $('#suffix').html($('#repo_name_suffix').val())

  $('#repo_name_suffix').on('input', ->
    $('#suffix').html(this.value)
  )

$(document).ready(ready)
