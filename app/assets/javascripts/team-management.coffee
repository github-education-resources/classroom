$('.groupings.show').ready ->

  dragula($('.member-list-draggable').toArray(), {
    revertOnSpill: true
  }).on('drop', (el, source, target) ->
    userId = el.children[0].getAttribute('user-id')
    sourceGroupId = source.getAttribute('group-id')
    targetGroupId = target.getAttribute('group-id')
  )
