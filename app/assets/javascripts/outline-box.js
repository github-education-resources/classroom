(function() {
  $('.js-outline-box-close').on('click', function() {
    Cookies.set('hide_permission_box', true, {
      expires: 365
    });
    return $(this).parents().eq(0).fadeOut('slow');
  });
}).call(this);
