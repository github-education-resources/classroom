$('.js-normalize-submit').on 'change keyup', ->
  resourceName = $(this).closest('form').attr('data-name')
  console.log $('.js-input-block').val()

  if $('.js-input-block').val() == resourceName
    $('.js-submit').prop('disabled', false)
  else
    $('.js-submit').prop('disabled', true)

$('.remodal-close').on 'click', ->
  $('.js-input-block').val('')
