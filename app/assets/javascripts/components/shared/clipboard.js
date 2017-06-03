import $ from 'jquery';
import Clipboard from 'clipboard';

let enableClipboardBtnRefresh = ($clipboardBtn) => {
  $($clipboardBtn).mouseover((e) => {
    return $(e.currentTarget).addClass('tooltipped tooltipped-s');
  });

  return $($clipboardBtn).mouseleave((e) => {
    let $currentTarget = $(e.currentTarget);
    $currentTarget.removeClass('tooltipped tooltipped-s');
    return $currentTarget.attr('aria-label', 'Copy to clipboard');
  });
}

let errorMessage = () => {
  if (/Mac/i.test(navigator.userAgent)) {
    return 'Press ⌘-C to copy';
  } else {
    return 'Press Ctrl-C to copy';
  }
}

let showTooltip = ($elem, msg) => {
  return $elem.attr('aria-label', msg);
};

$(document).on('turbolinks:load', () => {
  let clipboard = new Clipboard('.js-clipboard');
  let $clipboardBtns = $('.js-clipboard');

  $clipboardBtns.each(function(_index, $clipboardBtn) {
    enableClipboardBtnRefresh($clipboardBtn);
  });

  clipboard.on('success', function(e) {
    return showTooltip($(e.trigger), 'Copied!');
  });

  clipboard.on('error', function(e) {
    return showTooltip($(e.trigger), errorMessage);
  });
});
