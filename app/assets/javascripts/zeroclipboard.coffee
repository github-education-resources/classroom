buttonOver = ->
  # Remove tooltip from native copy button.
  this.classList.remove 'tooltipped', 'tooltipped-s'

  # Add a tooltip to the bridge.
  aria_label = $(this).attr 'aria-label'
  $('#global-zeroclipboard-html-bridge')
    .addClass('tooltipped tooltipped-s')
    .attr('aria-label', aria_label or 'Copy to clipboard.')

buttonOut = ->
  $('#global-zeroclipboard-html-bridge')
    .removeClass('tooltipped tooltipped-s')

$button = $('.js-zeroclipboard')
$button.hover(buttonOver, buttonOut)

zeroClipboardClient = new ZeroClipboard($button)

zeroClipboardClient.on('ready', ->

  zeroClipboardClient.on('copy', (event) ->
    url = $('.js-url-field').val().toString()
    event.clipboardData.setData('text/plain', url)
  )

  zeroClipboardClient.on('aftercopy', ->
    $('#global-zeroclipboard-html-bridge')
      .attr('aria-label', 'Copied!')

    $button.mouseleave( ->
      $('#global-zeroclipboard-html-bridge')
        .attr('Copy to clipboard')
    )
  )
)

zeroClipboardClient.on('error', ->
  zeroClipboardClient.destroy()
  $button.addClass('disabled')
)
