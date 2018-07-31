(function() {
  var POLL_INTERVAL = 1000;
  var display_progress,
    display_text,
    flash_error,
    flash_progress,
    flash_text,
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
    set_progress,
    set_progress_green,
    set_progress_red,
    setup_retry_button,
    setup_cable,
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

  set_progress_green = function(step_indicator) {
    var progress = step_indicator.find(".progress");
    if (progress.hasClass("bg-red")) {
      progress.removeClass("bg-red");
    }
    if (!progress.hasClass("bg-green")) {
      progress.addClass("bg-green");
    }
  };

  set_progress_red = function(step_indicator) {
    var progress = step_indicator.find(".progress");
    if (progress.hasClass("bg-green")) {
      progress.removeClass("bg-green");
    }
    if (!progress.hasClass("bg-red")) {
      progress.addClass("bg-red");
    }
  };

  set_progress = function(step_indicator, percent) {
    step_indicator.find(".progress").width(percent + "%");
  };

  indicate_waiting = function(step_indicator) {
    hide_border_and_background(step_indicator);
    set_progress_green(step_indicator);
  };

  indicate_completion = function(step_indicator) {
    hide_border_and_background(step_indicator);
    step_indicator.addClass("border-green bg-green-light");
    set_progress_green(step_indicator);
  };

  indicate_failure = function(step_indicator) {
    hide_border_and_background(step_indicator);
    step_indicator.addClass("border-red bg-red-light");
    set_progress_red(step_indicator);
  };

  indicate_in_progress = function(step_indicator) {
    hide_border_and_background(step_indicator);
    step_indicator.addClass("border-green bg-white");
    set_progress_green(step_indicator);
  };

  display_text = function(step_indicator, text) {
    var paragraph = step_indicator.find(".alt-text-small");
    paragraph.text(text);
  };

  display_progress = function(progress) {
    var create_repo_progress_indicator = $("#create-repo-progress");
    var import_repo_progress_indicator = $("#import-repo-progress");
    switch(progress.status) {
      case "waiting":
        indicate_waiting(create_repo_progress_indicator);
        indicate_waiting(import_repo_progress_indicator);
        set_progress(create_repo_progress_indicator, 0);
        set_progress(import_repo_progress_indicator, 0);
        display_text(create_repo_progress_indicator, "Waiting...");
        display_text(import_repo_progress_indicator, "Waiting...");
        hide_retry_button();
        break;
      case "creating_repo":
        indicate_in_progress(create_repo_progress_indicator);
        indicate_waiting(import_repo_progress_indicator);
        set_progress(create_repo_progress_indicator, 50);
        set_progress(import_repo_progress_indicator, 0);
        display_text(create_repo_progress_indicator, "Creating GitHub repository...");
        display_text(import_repo_progress_indicator, "Waiting...");
        hide_retry_button();
        break;
      case "importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_in_progress(import_repo_progress_indicator);
        set_progress(create_repo_progress_indicator, 100);
        set_progress(import_repo_progress_indicator, progress.percent);
        display_text(create_repo_progress_indicator, "Done");
        display_text(import_repo_progress_indicator, progress.status_text);
        hide_retry_button();
        break;
      case "errored_creating_repo":
        indicate_failure(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        display_text(create_repo_progress_indicator, "Errored");
        display_text(import_repo_progress_indicator, "Errored");
        show_retry_button();
        break;
      case "errored_importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        display_text(create_repo_progress_indicator, "Done");
        display_text(import_repo_progress_indicator, "Errored");
        show_retry_button();
        break;
      case "completed":
        indicate_completion(create_repo_progress_indicator);
        indicate_completion(import_repo_progress_indicator);
        set_progress(create_repo_progress_indicator, 100);
        set_progress(import_repo_progress_indicator, 100);
        display_text(create_repo_progress_indicator, "Done");
        display_text(import_repo_progress_indicator, "Done");
        hide_retry_button();
        setTimeout(show_success, 500);
        break;
    }
    flash_progress(progress);
  };

  flash_progress = function(progress) {
    if (progress.error) {
      flash_error(progress.error);
    } else if (progress.text) {
      flash_text(progress.text);
    } else {
      $("#flash-messages").empty();
    }
  };

  flash_error = function(error) {
    $("#flash-messages")
      .html("<div class='flash-application container-lg'><div class='flash flash-error'>" + error + "</div></div>");
  };

  flash_text = function(text) {
    $("#flash-messages")
      .html("<div class='flash-application container-lg'><div class='flash flash-success'>" + text + "</div></div>");
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

  setup_cable = function() {
    App.repository_creation_status = App.cable.subscriptions.create("RepositoryCreationStatusChannel", {
      connected: function() {
        // Called when the subscription is ready for use on the server
        start_job();
      },

      disconnected: function() {
        // Called when the subscription has been terminated by the server
      },

      received: function(data) {
        display_progress(data);
        // Called when there's incoming data on the websocket for this channel
      }
    });
  };

  ready = (function() {
    var setup_progress = $(".setupv2");
    if (setup_progress.length !== 0) {
      setup_retry_button();
      setup_cable();
    }
  });

  $(document).ready(ready);
}).call(this);
