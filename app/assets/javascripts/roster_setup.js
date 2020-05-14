(function(){
  var PROGRESS_HALF_LIFE = 1000;
  var setup_roster_update_cable,
  progress_asymptotically,
  display_message,
  set_progress,
  display_progress_bar,
  initialize_progress;

  var progress_complete = false;
  setup_roster_update_cable = function(){
    var roster_id = $("#current_roster_id").val();
    var user_id = $("#current_user_id").val();
    App.add_students_to_roster = App.cable.subscriptions.create({
      channel: "AddStudentsToRosterChannel",
      roster_id: roster_id,
      user_id: user_id
    },
    {
      connected: function() {
        // Called when the subscription is ready for use on the server
      },

      disconnected: function() {
        // Called when the subscription has been terminated by the server
      },

      received: function(data) {
        // Called when there's incoming data on the websocket for this channel
        if(data.status == "completed"){
          progress_complete = true;
          set_progress(100);
          display_message(data.message);
        }
      }
    });
  };

  progress_asymptotically = function() {
    recursive_progress_asymptotically = function(recursive_callback, counter) {
      var progress;
      var remaining = 100/counter;
      progress = 100 - (100/counter);
      $(document)
      .find(".roster-update-progress-bar")
      .animate(
        { width: progress.toFixed() + "%" },
        { duration: PROGRESS_HALF_LIFE * counter }
      );
      setTimeout(function() {
        if(!progress_complete){
          recursive_callback(recursive_callback, counter + 1);
        }
      },
      PROGRESS_HALF_LIFE * counter
    );
  };
  recursive_progress_asymptotically(recursive_progress_asymptotically, 1);
};

display_message = function(message){
  $(".roster-update-message").removeAttr("hidden");
  $("#roster-progress").text(message);
};

set_progress = function(percent) {
  $(".roster-update-progress-bar").stop(true, false);
  if (percent === 0) {
    $(".roster-update-progress-bar").css("width", 0);
  } else if (percent) {
    $(".roster-update-progress-bar").animate({width: percent + "%"});
  }
};

toggle_roster_form = function(disable_fields){
    var text_area = $("#entries-field");
    var csv_button = $("#file-upload");
    if(disable_fields){
      text_area.attr("disabled", "disabled");
      csv_button.addClass("disabled");
    }else{
      text_area.removeAttr("disabled");
      csv_button.removeClass("disabled");
    }
};

ready = (function(){
  $("#add-students-roster-form").on("ajax:beforeSend", function(){
    toggle_roster_form(true);
    $('.roster-update-progress').removeAttr("hidden");
    progress_asymptotically();
  });

  $("#add-students-roster-form").on("ajax:complete", function(){
    toggle_roster_form(false);
    $("#entries-field").val("");
  });

  $(document).on('closing', '[data-remodal-id=new-student-modal]', function (e) {
    set_progress("0");
    $('.roster-update-progress').attr("hidden", "hidden");
  });

  setup_roster_update_cable();
});

$(document).ready(ready);

}).call(this);
