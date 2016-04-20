showTooltip = ($elem, msg) ->
  $elem.attr('aria-label', msg)

$(document).ready ->
  clipboards = new Clipboard('.js-clipboard')

  for clipboardBtn in $('.js-clipboard')
    do ->
      $(clipboardBtn).mouseover (e) ->
        $(e.currentTarget).addClass('tooltipped tooltipped-s')

      $(clipboardBtn).mouseleave (e) ->
        $currentTarget = $(e.currentTarget)

        $currentTarget.removeClass('tooltipped tooltipped-s')
        $currentTarget.attr('aria-label', 'Copy to clipboard')

  clipboards.on('success', (e) -> showTooltip $(e.trigger), 'Copied!')

  if jQuery.browser.mobile
    copyMessage = 'Sorry cannot be copied'
  else if /Mac/i.test(navigator.userAgent)
    copyMessage = 'Press ⌘-C to copy'
  else
    copyMessage = 'Press Ctrl-C to copy'

  clipboards.on('error', (e) -> showTooltip $(e.trigger), copyMessage)
