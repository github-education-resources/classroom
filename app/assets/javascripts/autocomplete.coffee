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
    $('.js-autocomplete-suggestions-list').html('')

scroll_element_to_visible = (element, container) ->
  container_scrollbar_offset = $(container).scrollTop()
  container_height = $(container).outerHeight()
  element_top = $(element).offset().top - $(element).offsetParent().offset().top
  element_height = $(element).outerHeight()

  if (
    element_top < container_scrollbar_offset ||
    element_top + element_height > container_scrollbar_offset + container_height
  )
    element.scrollIntoView()

highlight_next_item = ->
  highlighted_items = $('.js-autocomplete-suggestion-item.highlighted')
  if highlighted_items.length == 0
    item = $('.js-autocomplete-suggestion-item').first()
  else
    nextItem = $(highlighted_items[0]).next()
    if nextItem.length > 0
      $(highlighted_items).removeClass('highlighted')
      item = nextItem.first()

  if item && item.length == 1
    item.addClass('highlighted')
    scroll_element_to_visible(item[0], $('.js-autocomplete-suggestions-container')[0])


highlight_previous_item = ->
  highlighted_items = $('.js-autocomplete-suggestion-item.highlighted')

  prevItem = $(highlighted_items[0]).prev()
  if prevItem.length > 0
    $(highlighted_items).removeClass('highlighted')
    item = prevItem.first()

  if item && item.length == 1
    item.addClass('highlighted')
    scroll_element_to_visible(item[0], $('.js-autocomplete-suggestions-container')[0])

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

        $('.js-autocomplete-suggestion-item').hover(->
          $(this).addClass('highlighted')
        , ->
          $(this).removeClass('highlighted')
        )

        set_suggestions_visible(true)
    ), 500
  )

  # handle non-input events
  $('.js-autocomplete-textfield').on('keydown', (event) ->
    if event.key == 'Enter'
      event.preventDefault()
      return false
  )

  $('.js-autocomplete-textfield').on('keyup', (event) ->
    return if event.ctrlKey || event.metaKey || event.shiftKey

    switch event.key
      when 'Enter'
        highlighted_items = $('.js-autocomplete-suggestion-item.highlighted')
        if highlighted_items.length == 1
          update_textfield(highlighted_items[0])
          set_suggestions_visible(false)
      when 'Escape'
        set_suggestions_visible(false)
      when 'ArrowUp'
        highlight_previous_item()
      when 'ArrowDown'
        highlight_next_item()
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
