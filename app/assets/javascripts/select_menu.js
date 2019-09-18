function initializeSelectMenu() {
  const $selectMenu            = $(".select-menu");
  const $selectMenuListItems   = $(".select-menu-item");
  const $selectMenuButton      = $(".select-menu-button");
  const $selectMenuCloseButton = $(".select-menu-close-button");

  $selectMenuButton.click(function() {
    $activeMenu = $(this);

    if ($activeMenu.attr("aria-expanded") === "true") {
      closeSelectMenu($activeMenu);
    } else {
      openSelectMenu($activeMenu);
    }
  });

  $selectMenuListItems.click(function(e) {
    const $clickedItem = $(e.target).closest($selectMenuListItems);
    const $activeMenuButton = $clickedItem.closest(".select-menu").find(".select-menu-button");

    selectItem($clickedItem);
    closeSelectMenu($activeMenuButton);

    $clickedItem.trigger("select");
  });

  $selectMenuCloseButton.click(function(e) {
    const $activeMenuButton = $(this).closest(".select-menu").find(".select-menu-button");

    closeSelectMenu($activeMenuButton);
  });

  function selectItem(item) {
    const $item = item;
    const $selectedItem = $item.closest(".select-menu-list").find(".selected");
    const $selectedOption = $item.closest(".select-menu").find(".selected-option");

    if($item === $selectedItem) return;

    $selectedOption.text(item.text());
    $selectedItem.find(".octicon").addClass("v-hidden");
    $selectedItem.removeClass("selected");

    $item.find(".octicon").removeClass("v-hidden");
    $item.addClass("selected");
  }

  function openSelectMenu(button) {
    const $button = button;
    const $modal = $button.siblings(".select-menu-modal-holder");

    $modal.addClass("active");
    $button.addClass("active");
    $button.attr("aria-expanded", "true");
  }

  function closeSelectMenu(button) {
    const $button = button;
    const $modal = $button.siblings(".select-menu-modal-holder");

    $modal.removeClass("active");
    $button.removeClass("active");
    $button.attr("aria-expanded", "false");
  }

    // Create public instance methods on the DOM Element
    if($selectMenu.get(0)) {
      $selectMenu.get(0).getOptionLinks = function() {
        var optionLinks = [];
        $selectMenuListItems.each(function() {
          optionLinks.push($(this).prop("href"));
        });

        return optionLinks;
      }

      $selectMenu.get(0).setOptionLinks = function(optionLinks) {
        $selectMenuListItems.each(function (index) {
          optionLink = optionLinks[index];
          $(this).prop("href", optionLink);
        });
      }
    }

  $(document).click(function(event) {
    const selectedButton = $selectMenu.find(event.target);

    if(selectedButton.length < 1) {
      closeSelectMenu(selectedButton);
    }
  });
};


$(document).ready(initializeSelectMenu)
