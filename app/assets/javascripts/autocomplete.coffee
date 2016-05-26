delay = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return

update_textfield = (list_element) ->
  $(list_element).removeClass('suggestion-focused')
  $('.js-autocomplete-textfield').val($(list_element).data('res-name'))
  $('.js-autocomplete-resource-id').val($(list_element).data('res-id'))

set_suggestions_visible = (visible) ->
  if visible
    $('.js-autocomplete-suggestions-container').show()
  else
    $('.js-autocomplete-suggestions-container').hide()

ready = ->
  $('.js-autocomplete-textfield').on('input', ->

    $('.js-autocomplete-resource-id').removeAttr('value')

    unless query = this.value.trim()
      set_suggestions_visible(false)
      return

    textfield = this

    $('.js-autocomplete-suggestions-list').html('')
    set_suggestions_visible(true)

    delay (->
      $.get "/autocomplete/#{$(textfield).data('autocomplete-search-endpoint')}?query=#{query}", (data) ->
        # handle outdated responses
        return unless query == textfield.value.trim() && $(textfield).is(':focus')

        $('.js-autocomplete-suggestions-list').html(data)

        $('.js-autocomplete-suggestion-item').click(->
          update_textfield(this)
          set_suggestions_visible(false)
        )

        set_suggestions_visible(true)
    ), 500
  )

  # Behavior:
  #   keep the suggestion list when:
  #     - right clicking
  #     - click js-autocomplete-textfield
  #     - click js-autocomplete-suggestion-item and its children
  #   dismiss the suggestion list when:
  #     - js-autocomplete-textfield and user click other element
  $(document).on('mousedown', (event) ->
    return if (
      event.button == 2 ||
      $(event.target).hasClass('js-autocomplete-suggestion-item') ||
      $(event.target).parents('.js-autocomplete-suggestion-item').length > 0 ||
      $(event.target).hasClass('js-autocomplete-textfield')
    )

    if $('.js-autocomplete-textfield').is(':focus')
      set_suggestions_visible(false)
  )

$(document).ready(ready)
