(function() {
  $('.js-flash-close').on('click', function() {
    return $(this).parents().eq(1).fadeOut('slow');
  });
}).call(this);
