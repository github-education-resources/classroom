$('#js-search-form').on('change keyup', ->
  $this = $(this)

  formData = $(this).serialize()
  history.replaceState(null, '', "?#{formData}")

  $this.submit()

  $this.on('ajax:success', (e, data, status, xhr) ->
    $('#js-search-results').html(xhr.responseText)
  )
)
