delay = do ->
  timer = 0
  (callback, ms) ->
    clearTimeout timer
    timer = setTimeout(callback, ms)
    return

update_textfield = (list_element) ->
  # remove focused state
  $(list_element).removeClass('suggestion-focused')
  $('#autocomplete-textfield').val($(list_element).find('.res-name')[0].innerHTML)

ready = ->
  # TODO: test with IE 8
  # onpropertychange -> oninput for IE 8
  # https://msdn.microsoft.com/en-us/library/ms536956(v=vs.85).aspx
  $('#autocomplete-textfield').on('focus input propertychange', ->
    return unless $(this).is(':focus')
    $this = $(this)
    textfield = this
    query = textfield.value

    # shows the container & loading indicator
    $('#autocomplete-loading-indicator').show()
    $('#autocomplete-suggestions-container').show()

    # clear old content
    $('#autocomplete-suggestions-list').html('')

    delay (->
      $.get "/autocomplete/#{textfield.name}?query=#{query}", (data) ->
        # handle outdated responses
        return unless query == textfield.value && $(textfield).is(':focus')

        # put new data into the container
        $('#autocomplete-suggestions-list').html(data)

        # hide indicator
        $('#autocomplete-loading-indicator').hide()

        # Resolve an issue with `onBlur`.
        # When clicking the item in the suggestion list,
        # the `onBlur` event will take place before `onClick`.
        # So when a user hovers the item, we can mark that item first
        # and retrieve the hovered item when `onBlur` is fired.
        $('.autocomplete-suggestion-item').hover(->
          $(this).addClass('suggestion-focused')
        , ->
          $(this).removeClass('suggestion-focused')
        )

        $('#autocomplete-suggestions-container').show()

    ), 200
  )

  $('#autocomplete-textfield').on('blur', ->
    # check if there's any selected item
    selected_items = $('.autocomplete-suggestion-item.suggestion-focused')

    # if so, update the value of the textfield
    update_textfield(selected_items.first()) if selected_items.length == 1

    # hide suggestion list
    $('#autocomplete-suggestions-container').hide()
  )


$(document).ready(ready)
