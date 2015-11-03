$('.js-outline-box-close').on 'click', ->
  Cookies.set('hide_permission_box', true, expires: 365)
  $(this).parents().eq(0).fadeOut('slow')
