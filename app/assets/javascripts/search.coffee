delay = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return

$('#js-search-form').on('change keyup', ->
  $this = $(this)

  formData = $(this).serialize()
  history.replaceState(null, '', "?#{formData}")

  delay (->
    $this.submit()

    $this.on('ajax:success', (e, data, status, xhr) ->
      $('#js-search-results').html(xhr.responseText)
    )
  ), 200
)
