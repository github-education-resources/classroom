(function() {
  var ready, check_progress, show_success, invitation_path, progress_path, sucess_path, display_progress, indicate_completion, indicate_in_progress;

  indicate_completion = function(step_indicator){
    $(step_indicator).addClass("border-green bg-green-light");

    var status, completion_indicator;
    status = $(step_indicator).find(".status");
    completion_indicator = $(status).find(".complete-indicator");

    if (!completion_indicator.hasClass("active")) {
      $(completion_indicator).addClass("active");
      $(status).find(".animated-ellipsis").remove();
    }
  };

  indicate_in_progress = function(step_indicator){
    var status_indicator;
    status_indicator = $(step_indicator).find(".status");

    if (!status_indicator.hasClass("animated-ellipsis-container")) {
      $(step_indicator).addClass("border-green");

      $(status_indicator).addClass("animated-ellipsis-container");
      $(status_indicator).prepend("<i class='animated-ellipsis'>.....</i>");
    }
  };

  finalize_progress = function(progress){
    var finalize_indicator = $("#finalize-progress");
    if (progress.status == "complete") {
      indicate_completion(finalize_indicator);
      show_success();
    }
  };

  configuration_progress = function(progress){
    var configuration_indicator = $("#config-progress");
    if (progress.status == "configuring") {
      indicate_in_progress(configuration_indicator);
    } else if (progress.status == "complete") {
      indicate_completion(configuration_indicator);
    }
  };

  import_progress = function(progress){
    var import_indicator = $("#import-progress");
    if (progress.status == "importing") {
      indicate_in_progress(import_indicator);
    } else {
      indicate_completion(import_indicator);
    }
  };

  display_progress = function(progress){
    import_progress(progress);
    configuration_progress(progress);
    finalize_progress(progress);
  };

  success_path = function () {
    return invitation_path()  + "/success";
  };

  progress_path = function () {
    return invitation_path()  + "/setup_progress";
  };

  invitation_path = function () {
    var progress_indicator, invitation_type, invitation_id, path;
    progress_indicator = $(".setup-progress");
    invitation_type    = $(progress_indicator).data("invitation");
    invitation_id      = $(progress_indicator).data("invitation-id");
    path               = "/";

    path += (invitation_type == "assignment" ? "assignment-invitations" : "group-assignment-invitations");
    return path += "/" + invitation_id;
  };

  show_success = function() {
    location.href = success_path();
  };

  check_progress = function() {
    var progress_indicator = $(".setup-progress");
    var path = progress_path();

    $.ajax({type: "PATCH", url: path}).done(function(data){
       display_progress(data);
       setTimeout(check_progress, 3000);
     });
  };

  ready  = (function() {
    var setup_progress = $(".setup-progress");
    if(setup_progress.length !== 0){
      var import_indicator = $("#import-progress");
      indicate_in_progress(import_indicator);
      check_progress();
    }
  });

  $(document).ready(ready);
}).call(this);
