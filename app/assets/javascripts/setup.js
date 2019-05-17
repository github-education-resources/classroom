(function() {
  var POLL_INTERVAL = 1000;
  var PROGRESS_HALF_LIFE = 1000;
  var progress_asymptotically,
    create_flash_container,
    display_progress,
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
    setup_assignment_cable,
    setup_group_assignment_cable,
    show_retry_button,
    show_success,
    start_job,
    success_path,
    wrap_in_parapgraph;

  var asymptotic_start_times = {
    "create-repo-progress": null,
    "import-repo-progress": null
  };

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
    step_indicator.find(".progress").stop(true, false);
    asymptotic_start_times[step_indicator.attr("id")] = null;
    if (percent === 0) {
      step_indicator.find(".progress").css("width", 0);
    } else if (percent) {
      step_indicator.find(".progress").animate({width: percent + "%"});
    }
  };

  progress_asymptotically = function(step_indicator) {
    start_time = Date.now();
    asymptotic_start_times[step_indicator.attr("id")] = start_time;
    recursive_progress_asymptotically = function(recursive_callback, counter) {
      if (asymptotic_start_times[step_indicator.attr("id")] !== start_time) {
        return;
      } else {
        var progress = 100 - (100/counter);
        step_indicator
          .find(".progress")
          .animate(
            { width: progress.toFixed() + "%" },
            { duration: PROGRESS_HALF_LIFE * counter }
          );
        setTimeout(function() {
            recursive_callback(recursive_callback, counter + 1);
          },
          PROGRESS_HALF_LIFE * counter
        );
      }
    };
    recursive_progress_asymptotically(recursive_progress_asymptotically, 1);
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
    paragraph.html(text);
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
        progress_asymptotically(create_repo_progress_indicator);
        set_progress(import_repo_progress_indicator, 0);
        display_text(create_repo_progress_indicator, "Creating GitHub repository...");
        display_text(import_repo_progress_indicator, "Waiting...");
        hide_retry_button();
        break;
      case "importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_in_progress(import_repo_progress_indicator);
        set_progress(create_repo_progress_indicator, 100);
        progress_asymptotically(import_repo_progress_indicator);
        if (progress.repo_url) {
          display_text(create_repo_progress_indicator, "Done: <a href=\"" + progress.repo_url + "\">" + progress.repo_url + "</a>");
        } else {
          display_text(create_repo_progress_indicator, "Done");
        }
        display_text(import_repo_progress_indicator, "Importing starter code...");
        hide_retry_button();
        break;
      case "errored_creating_repo":
        indicate_failure(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        display_text(create_repo_progress_indicator, "Errored");
        display_text(import_repo_progress_indicator, "Errored");
        set_progress(create_repo_progress_indicator, null);
        set_progress(import_repo_progress_indicator, null);
        show_retry_button();
        break;
      case "errored_importing_starter_code":
        indicate_completion(create_repo_progress_indicator);
        indicate_failure(import_repo_progress_indicator);
        display_text(create_repo_progress_indicator, "Done");
        display_text(import_repo_progress_indicator, "Errored");
        set_progress(create_repo_progress_indicator, null);
        set_progress(import_repo_progress_indicator, null);
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

  wrap_in_parapgraph = function(text) {
    return "<p>" + text + "</p>";
  };

  flash_progress = function(progress) {
    if (progress.error) {
      create_flash_container();
      flash_error(wrap_in_parapgraph(progress.error));
    } else if (progress.text) {
      create_flash_container();
      flash_text(wrap_in_parapgraph(progress.text));
    } else {
      $("#flash-messages").empty();
    }
  };

  create_flash_container = function() {
    $("#flash-messages")
      .html("<div class='flash-application container-lg'></div>");
  };

  flash_error = function(error) {
    $("#flash-messages").find(".flash-application")
      .append("<div class='flash flash-error'>" + error + "</div>");
  };

  flash_text = function(text) {
    $("#flash-messages").find(".flash-application")
      .append("<div class='flash flash-success'>" + text + "</div>");
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

  setup_assignment_cable = function() {
    var assignment_id = $("#assignment_id").val();
    App.repository_creation_status = App.cable.subscriptions.create(
      {
        channel: "RepositoryCreationStatusChannel",
        assignment_id: assignment_id
      }, {
        connected: function() {
          // Called when the subscription is ready for use on the server
          start_job();
        },
        disconnected: function() {
          // Called when the subscription has been terminated by the server
        },
        received: function(data) {
          // Called when there's incoming data on the websocket for this channel
          display_progress(data);
        }
      }
    );
  };

  setup_group_assignment_cable = function() {
    var group_id = $("#group_id").val();
    var group_assignment_id = $("#group_assignment_id").val();
    App.repository_creation_status = App.cable.subscriptions.create(
      {
        channel: "GroupRepositoryCreationStatusChannel",
        group_id: group_id,
        group_assignment_id: group_assignment_id
      }, {
        connected: function() {
          // Called when the subscription is ready for use on the server
          start_job();
        },
        disconnected: function() {
          // Called when the subscription has been terminated by the server
        },
        received: function(data) {
          // Called when there's incoming data on the websocket for this channel
          display_progress(data);
        }
      }
    );
  };

  ready = (function() {
    var assignment_setup = $("#assignment_setup");
    var group_assignment_setup = $("#group_assignment_setup");
    if (assignment_setup.length !== 0) {
      setup_retry_button();
      setup_assignment_cable();
    } else if (group_assignment_setup.length !== 0) {
      setup_retry_button();
      setup_group_assignment_cable();
    }
  });

  $(document).ready(ready);
}).call(this);
