$('.js-flash-close').on 'click', ->
  $(this).parents().eq(1).fadeOut('slow')
