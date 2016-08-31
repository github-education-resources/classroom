generate_slug = (title) ->
  return '' unless !!title

  slug = slugify(title)
  slug = '-' unless !!slug
  return slug


$('.assignments').ready( ->
  $('#assignment_title').on('change paste keyup click', ->
    $('#assignment_slug').val(generate_slug($('#assignment_title').val()))
  )
)

$('.group_assignments').ready( ->
  $('#group_assignment_title').on('change paste keyup click', ->
    $('#group_assignment_slug').val(generate_slug($('#group_assignment_title').val()))
  )
)
