update_student_count_text = (group, groupId) ->
  group_description = $("div").find("[group-description-id='" + groupId + "']")
  if (group.childElementCount == 1)
    group_description.text(group.childElementCount + ' student')
  else
    group_description.text(group.childElementCount + ' students')

show_flash_message = (msg, type) ->
  $("#flash-messages").html("<div class='flash-application container'><div class='flash #{type}'>#{msg}</div></div>")
  fade_flash_message()

fade_flash_message = ->
  $('.flash-application').delay(3000).fadeOut("slow")

$('.groupings.show').ready ->

  drake = dragula($('.member-list-draggable').toArray(), {
    revertOnSpill: true
  })

  drake.on('drop', (el, target, source) ->
    user_id = el.children[0].getAttribute('user-id')
    source_group_id = source.getAttribute('group-id')
    target_group_id = target.getAttribute('group-id')

    $.ajax({
      type: 'DELETE',
      url: "/classrooms/#{organization_id}/groupings/#{grouping_id}/groups/#{source_group_id}/memberships/#{user_id}"
      success: (response) ->
        $.ajax({
          type: 'PATCH',
          url: "/classrooms/#{organization_id}/groupings/#{grouping_id}" +
           "/groups/#{target_group_id}/memberships/#{user_id}"
        }).done( ->
          update_student_count_text(source, source_group_id)
          update_student_count_text(target, target_group_id)
        )
      error: (jqXHR, exception) ->
        show_flash_message(jqXHR.responseJSON.message, 'flash-error')
        target.removeChild(el)
        source.appendChild(el)
    })
  )
