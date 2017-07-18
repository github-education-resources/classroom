(function() {
  var fade_flash_message, show_flash_message, update_student_count_text;

  update_student_count_text = function(group, groupId) {
    var group_description;
    group_description = $("div").find("[group-description-id='" + groupId + "']");
    if (group.childElementCount === 1) {
      return group_description.text(group.childElementCount + ' student');
    } else {
      return group_description.text(group.childElementCount + ' students');
    }
  };

  show_flash_message = function(msg, type) {
    $("#flash-messages").html("<div class='flash-application container-lg'><div class='flash " + type + "'>" + msg + "</div></div>");
    return fade_flash_message();
  };

  fade_flash_message = function() {
    return $('.flash-application').delay(3000).fadeOut("slow");
  };

  $('.groupings.show').ready(function() {
    var drake;
    drake = dragula($('.member-list-draggable').toArray(), {
      revertOnSpill: true
    });
    return drake.on('drop', function(el, source, target) {
      var source_group_id, target_group_id, user_id;
      user_id = el.children[0].getAttribute('user-id');
      source_group_id = source.getAttribute('group-id');
      target_group_id = target.getAttribute('group-id');
      update_student_count_text(source, source_group_id);
      return update_student_count_text(target, target_group_id);
    });
  });
}).call(this);
