(function() {
  var is_new_window_or_tab_event, ready;

  // A new window/tab event can be one of the following
  // ctrlKey (Windows)
  // metaKey (OSX)
  // shiftKey (OS agnositc)
  // New tab with middle click
  is_new_window_or_tab_event = function(event) {
    var middle_click_event;
    middle_click_event = event.button && event.button === 1;
    return event.ctrlKey || event.metaKey || event.shiftKey || middle_click_event;
  };

  ready = function() {
    return $('.js-navigation').on('click', function(event) {
      if (is_new_window_or_tab_event(event)) {
        return;
      }
      $('.loading-indicator').show();
      $('body').addClass('no-scroll');
      return $('body').on('touchmove', function(e) {
        return e.preventDefault();
      });
    });
  };

  $(document).ready(ready);
}).call(this);
