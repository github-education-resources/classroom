(function() {
  var POLL_INTERVAL = 3000;
  var check_progress,
    display_progress,
    get_status,
    hide_border_and_background,
    hide_indicator_image,
    hide_retry_button,
    indicate_completion,
    indicate_failure,
    indicate_in_progress,
    indicate_waiting,
    invitation_path,
    is_hidden,
    progress_path,
    ready,
    setup_retry_button,
    show_retry_button,
    show_success,
    start_job,
    success_path;

  is_hidden = function(element) {
    return element.hasClass("d-none");
  };

  show_retry_button = function() {
    var retry_button = $("#retry-button");
    if (is_hidden(retry_button)) {
      retry_button.removeClass("d-none");
    }
  };

  hide_retry_button = function() {
    var retry_button = $("#retry-button");
    if (!is_hidden(retry_button)) {
      retry_button.addClass("d-none");
    }
  };

  hide_border_and_background = function(step_indicator) {
    if (step_indicator.hasClass("border-green bg-green-light")) {
      step_indicator.removeClass("border-green bg-green-light");
    }
    if (step_indicator.hasClass("border-red bg-red-light")) {
      step_indicator.removeClass("border-red bg-red-light");
    }
    if (step_indicator.hasClass("border-green bg-white")) {
      step_indicator.removeClass("border-green bg-white");
    }
  };

  hide_indicator_image = function(step_indicator) {
    var status = step_indicator.find(".status");
    status.find(".complete-indicator").hide();
    status.find(".failure-indicator").hide();
    status.find(".spinner").hide();
  };

  get_status = function(step_indicator) {
    var status = step_indicator.find(".status");
    if (is_hidden(status)) {
      status.removeClass("d-none");
    }
    return status;
  };

  indicate_waiting = function(step_indicator) {
    hide_border_and_background(step_indicator);
    hide_indicator_image(step_indicator);
  };

  indicate_completion = function(step_indicator) {
    hide_border_and_background(step_indicator);
    hide_indicator_image(step_indicator);
    step_indicator.addClass("border-green bg-green-light");
    var status = get_status(step_indicator);

    status.find(".complete-indicator").show();
  };

  indicate_failure = function(step_indicator) {
    hide_border_and_background(step_indicator);
    hide_indicator_image(step_indicator);
    step_indicator.addClass("border-red bg-red-light");
    var status = get_status(step_indicator);

    status.find(".failure-indicator").show();
  };

  indicate_in_progress = function(step_indicator) {
    hide_border_and_background(step_indicator);
    hide_indicator_image(step_indicator);
    step_indicator.addClass("border-green bg-white");
    var status = get_status(step_indicator);

    status.find(".spinner").show();
  };

  display_progress = function(progress) {
    var create_repo_progress_indicator = $("#create-repo-progress");
    var import_repo_progress_indicator = $("#import-repo-progress");
    switch(progress.status) {
      case "waiting":
        indicate_waiting(create_repo_progress_indicator);
        indicate_waiting(import_repo_progress_indicator);
        hide_retry_button();
        break;
      case "creating_repo":
        indicate_in_progress(create_repo_progress_indicator);
        indicate_waiting(import_repo_progress_indicator);
        hide_retry_button();
        break;
      case "importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_in_progress(import_repo_progress_indicator);
        hide_retry_button();
        break;
      case "errored_creating_repo":
        indicate_failure(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        show_retry_button();
        break;
      case "errored_importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        show_retry_button();
        break;
      case "completed":
        indicate_completion(create_repo_progress_indicator);
        indicate_completion(import_repo_progress_indicator);
        hide_retry_button();
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

  start_job = function(callback) {
    var path = job_path();
    $.ajax({type: "POST", url: path}).done(function(data) {
      display_progress(data);
      if (callback) {
        callback();
      }
    });
  };

  setup_retry_button = function() {
    var retry_button = $("#retry-button");
    retry_button.click(function() {
      retry_button.addClass("disabled");
      start_job(function() {
        retry_button.removeClass("disabled");
      });
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
