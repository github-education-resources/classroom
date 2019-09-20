$(document).ready(function() {
  const $searchAndSort = $("#js-search-and-sort-component");

  if (!$searchAndSort) return;

  const debounce = (function() {
    let timer = 0;

    return function(callback, ms) {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(callback, ms);
    };
  })();

  $("#js-filtering-component").on("change keyup input", function(e) {
    const componentContext = $(e.target).closest("#js-filtering-component");
    const $searchForm = componentContext.find("#js-filtering-form");
    const formData = $searchForm.find('input[name!=utf8]').serialize();

    history.replaceState(null, '', '?' + formData);
    debounce(function() { $searchForm.submit(); }, 300);
  });

  $("#js-filtering-component .SelectMenu-item").on("change", function(e) {
    const $clickedItem = $(e.target).closest(".SelectMenu-item");
    const $currentActiveItem = $clickedItem.siblings("[aria-checked='true']");
    const $currentMenu = $clickedItem.closest('details');

    $currentActiveItem.attr("aria-checked", false);
    $clickedItem.attr("aria-checked", true);
    $currentMenu.find("[data-menu-button]").text($clickedItem.text())
    $currentMenu.removeAttr('open')
  });
});
