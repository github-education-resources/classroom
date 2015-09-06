$('.js-normalize-submit').on 'change keyup', ->
  organizationTitle = $(this).closest('form').attr('data-organization-name')

  if $('.js-input-block').val() == organizationTitle
    $('.js-btn-close').prop('disabled', false)
  else
    $('.js-btn-close').prop('disabled', true)

$('.js-close').on 'click', ->
  $('.js-input-block').val('')
