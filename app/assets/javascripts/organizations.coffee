update_new_clssroom_btn_visibility = ->
  if $('.js-organization-list-item').length > 0
    $('.js-new-classroom-btn').show()
  else
    $('.js-new-classroom-btn').hide()

ready = ->
  update_new_clssroom_btn_visibility()

  $('.js-organization-list').ready ->
    $this = $(this)
    $.get $this.data('ajax-load-path'),
          (data) ->
            $this.html(data)
            $('.js-tiny-loading-indicator').hide()
            update_new_clssroom_btn_visibility()

$(document).ready(ready)
