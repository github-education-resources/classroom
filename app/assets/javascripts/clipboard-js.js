(function() {
  var showTooltip;

  showTooltip = function($elem, msg) {
    return $elem.attr('aria-label', msg);
  };

  $(document).ready(function() {
    var clipboardBtn, clipboards, copyMessage, fn, i, len, ref;
    clipboards = new Clipboard('.js-clipboard');
    ref = $('.js-clipboard');
    fn = function() {
      $(clipboardBtn).mouseover(function(e) {
        return $(e.currentTarget).addClass('tooltipped tooltipped-s');
      });
      return $(clipboardBtn).mouseleave(function(e) {
        var $currentTarget;
        $currentTarget = $(e.currentTarget);
        $currentTarget.removeClass('tooltipped tooltipped-s');
        return $currentTarget.attr('aria-label', 'Copy to clipboard');
      });
    };
    for (i = 0, len = ref.length; i < len; i++) {
      clipboardBtn = ref[i];
      fn();
    }
    clipboards.on('success', function(e) {
      return showTooltip($(e.trigger), 'Copied!');
    });
    if (/Mac/i.test(navigator.userAgent)) {
      copyMessage = 'Press ⌘-C to copy';
    } else {
      copyMessage = 'Press Ctrl-C to copy';
    }
    return clipboards.on('error', function(e) {
      return showTooltip($(e.trigger), copyMessage);
    });
  });
}).call(this);
