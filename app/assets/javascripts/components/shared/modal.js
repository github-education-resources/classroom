import $ from 'jquery';
import 'remodal';

$(document).on('turbolinks:load', () => {
  $('.js-normalize-submit').on('change keyup', function() {
    let resourceName = $(this).closest('form').attr('data-name');
    if ($('.js-input-block').val() === resourceName) {
      return $('.js-submit').prop('disabled', false);
    } else {
      return $('.js-submit').prop('disabled', true);
    }
  });

  return $('.remodal-close').on('click', function() {
    return $('.js-input-block').val('');
  });
})
