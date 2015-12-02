ready = ->
  $('.js-normalize-submit').on 'change keyup', ->
    resourceName = $(this).closest('form').attr('data-name')

    if $('.js-input-block').val() == resourceName
      $('.js-submit').prop('disabled', false)
    else
      $('.js-submit').prop('disabled', true)

  $('.remodal-close').on 'click', ->
    $('.js-input-block').val('')

$(document).ready(ready)
