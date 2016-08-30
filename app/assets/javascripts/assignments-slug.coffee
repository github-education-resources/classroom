ready = ->
  $('#assignment_title').on('keyup', ->
    $('#assignment_slug').val($('#assignment_title').val().toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,''));
  )

$('.assignments').ready(ready)

