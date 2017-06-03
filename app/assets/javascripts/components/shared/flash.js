import $ from 'jquery';

$(document).on('turbolinks:load', () => {
  $('.js-flash-close').on('click', () => {
    return $(this).parents().eq(1).fadeOut('slow');
  });
});
