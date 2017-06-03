import $ from 'jquery';

// A new window/tab event can be one of the following
// ctrlKey (Windows)
// metaKey (OSX)
// shiftKey (OS agnositc)
// New tab with middle click
let isNewWindowOrTabEvent = (event) => {
  let middleClickEvent = event.button && event.button === 1;
  return event.ctrlKey || event.metaKey || event.shiftKey || middleClickEvent;
}

$(document).on('turbolinks:load', () => {
  $('.js-navigation').on('click', () => {
    if (isNewWindowOrTabEvent(event)) { return; }

    $('.loading-indicator').show();
    $('body').addClass('no-scroll');

    return $('body').on('touchmove', (e) => {
      return e.preventDefault();
    });
  });
});
