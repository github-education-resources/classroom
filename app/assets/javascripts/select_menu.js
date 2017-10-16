$(document).ready(function() {
  select_menu              = $(".select-menu");
  select_menu_modal        = $(".select-menu-modal-holder");
  select_menu_button       = $(".select-menu-button");
  select_menu_close_button = $(".select-menu-close-button");

  select_menu.click(function(event) {
    event.stopPropagation();
  });

  select_menu_button.click(function() {
    if (select_menu_button.attr("aria-expanded") === "true") {
      closeSelectMenu();
    } else {
      openSelectMenu();
    }
  });

  select_menu_close_button.click(function(e) {
    closeSelectMenu();
  });

  function openSelectMenu() {
    select_menu_modal.addClass("active");
    select_menu_button.addClass("active");
    select_menu_button.attr("aria-expanded", "true");
  }

  function closeSelectMenu() {
    select_menu_modal.removeClass("active");
    select_menu_button.removeClass("active");
    select_menu_button.attr("aria-expanded", "false");
  }

  $(document).click(function() {
    closeSelectMenu();
  });
});
