$('.assignments').ready( ->
  $('#assignment_title').on('change paste keyup click', ->
    $('#assignment_slug').val(slugify($('#assignment_title').val()))
  )
)

$('.group_assignments').ready( ->
  $('#group_assignment_title').on('change paste keyup click', ->
    $('#group_assignment_slug').val(slugify($('#group_assignment_title').val()))
  )
)
