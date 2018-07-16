(function() {
  var POLL_INTERVAL = 3000;
  var check_progress,
    display_progress,
    display_retry_button,
    hide_retry_button,
    indicate_completion,
    indicate_failure,
    indicate_in_progress,
    invitation_path,
    progress_path,
    ready,
    setup_retry_button,
    show_success,
    start_job,
    success_path;

  indicate_completion = function(step_indicator) {
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

    hide_retry_button();
  };

  indicate_failure = function(step_indicator) {
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

    display_retry_button();
  };

  indicate_in_progress = function(step_indicator) {
    var status;
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

    hide_retry_button();
  };

  display_retry_button = function() {
    var retry_button = $("#retry-button");
    if (retry_button.hasClass("d-none")) {
      retry_button.removeClass("d-none");
    }
  };

  hide_retry_button = function() {
    var retry_button = $("#retry-button");
    if (!retry_button.hasClass("d-none")) {
      retry_button.addClass("d-none");
    }
  };

  display_progress = function(progress) {
    var create_repo_progress_indicator = $("#create-repo-progress");
    var import_repo_progress_indicator = $("#import-repo-progress");
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
    }
  };

  success_path = function () {
    return invitation_path() + "/success";
  };

  progress_path = function () {
    return invitation_path() + "/progress";
  };

  job_path = function () {
    return invitation_path() + "/create_repo";
  };

  invitation_path = function () {
    var pathname = window.location.pathname;
    var path_components = pathname.split("/");
    path_components.pop();
    return path_components.join("/");
  };

  show_success = function() {
    location.href = success_path();
  };

  check_progress = function() {
    var path = progress_path();
    $.ajax({type: "GET", url: path}).done(function(data) {
      display_progress(data);
      setTimeout(check_progress, POLL_INTERVAL);
    });
  };

  start_job = function() {
    var path = job_path();
    $.ajax({type: "POST", url: path}).done(function(data) {
      display_progress(data);
    });
  };

  setup_retry_button = function() {
    $("#retry-button").click(function() {
      location.reload();
    });
  };

  ready = (function() {
    var setup_progress = $(".setupv2");
    if (setup_progress.length !== 0) {
      setup_retry_button();
      start_job();
      check_progress();
    }
  });

  $(document).ready(ready);
}).call(this);
