$('.groupings.show').ready ->
  dragula($('.member-list-draggable').toArray(), {
    revertOnSpill: true
  })
