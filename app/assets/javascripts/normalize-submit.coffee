$('.js-normalize-submit').on 'change keyup', ->
  resourceName = $(this).closest('form').attr('data-name')

  if $('.js-input-block').val() == resourceName
    $('.js-btn-close').prop('disabled', false)
  else
    $('.js-btn-close').prop('disabled', true)

$('.js-close').on 'click', ->
  $('.js-input-block').val('')
