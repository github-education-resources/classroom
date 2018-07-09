(function() {
  var ready, check_progress, show_success, invitation_path, progress_path, success_path, display_progress, indicate_completion, indicate_failure, indicate_in_progress;

  indicate_completion = function(step_indicator){
    $(step_indicator).addClass("border-green bg-green-light");

    var status, completion_indicator;
    status = $(step_indicator).find(".status");
    if (status.hasClass("d-none")) {
      status.removeClass("d-none");
    }

    completion_indicator = $(status).find(".complete-indicator");
    failure_indicator = $(status).find(".failure-indicator");
    spinner_indicator = $(status).find(".spinner");

    $(completion_indicator).show();
    $(failure_indicator).hide();
    $(spinner_indicator).hide();
  };

  indicate_failure = function(step_indicator){
    $(step_indicator).addClass("border-red bg-red-light");

    var status, failure_indicator;
    status = $(step_indicator).find(".status");
    if (status.hasClass("d-none")) {
      status.removeClass("d-none");
    }

    completion_indicator = $(status).find(".complete-indicator");
    failure_indicator = $(status).find(".failure-indicator");
    spinner_indicator = $(status).find(".spinner");

    $(failure_indicator).show();
    $(completion_indicator).hide();
    $(spinner_indicator).hide();
  };

  indicate_in_progress = function(step_indicator){
    let status;
    status = $(step_indicator).find(".status");
    if (status.hasClass("d-none")) {
      status.removeClass("d-none");
    }

    completion_indicator = $(status).find(".complete-indicator");
    failure_indicator = $(status).find(".failure-indicator");
    spinner_indicator = $(status).find(".spinner");

    $(step_indicator).addClass("border-green");

    $(spinner_indicator).show();
    $(failure_indicator).hide();
    $(completion_indicator).hide();
  };

  display_progress = function(progress) {
    let create_repo_progress_indicator = $("#create-repo-progress");
    let import_repo_progress_indicator = $("#import-repo-progress");
    switch(progress.status) {
      case "creating_repo":
        indicate_in_progress(create_repo_progress_indicator);
        break;
      case "importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_in_progress(import_repo_progress_indicator);
        break;
      case "errored":
        indicate_failure(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        break;
      case "completed":
        indicate_completion(create_repo_progress_indicator);
        indicate_completion(import_repo_progress_indicator);
        setTimeout(show_success, 500);
        break;
    };
  };

  success_path = function () {
    return invitation_path() + "/success";
  };

  progress_path = function () {
    return invitation_path() + "/progress";
  };

  invitation_path = function () {
    const pathname = window.location.pathname
    let path_components = pathname.split("/");
    path_components.pop();
    return path_components.join("/");
  };

  show_success = function() {
    location.href = success_path();
  };

  check_progress = function() {
    const path = progress_path();

    $.ajax({type: "GET", url: path}).done(function(data){

      console.log(data) // remove this
      display_progress(data);
      setTimeout(check_progress, 3000);
    });
  };

  ready = (function() {
    const setup_progress = $(".setupv2");
    if (setup_progress.length !== 0){
      check_progress();
    }
  });

  $(document).ready(ready);
}).call(this);
