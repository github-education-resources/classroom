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

  $("#js-filtering-form").on("change keyup input", function(e) {
    const searchForm = document.getElementById("js-filtering-form");
    const formData = $(searchForm).find('input[name!=utf8]').serialize();

    history.replaceState(null, '', '?' + formData);
    // Can't use .submit() here as it does not make request via XHR
    debounce(function() { searchForm.dispatchEvent(new Event('submit', {bubbles: true})); }, 300);
  });

  $("#js-filtering-form .SelectMenu-item").on("change", function(e) {
    const clickedItem = e.target.closest(".SelectMenu-item");
    const currentMenu = clickedItem.closest("details");
    const currentActiveItem = currentMenu.querySelector("[aria-checked=true]");

    currentActiveItem.setAttribute("aria-checked", false);
    clickedItem.setAttribute("aria-checked", true);
    currentMenu.querySelector("[data-menu-button]").innerText = clickedItem.innerText;
    currentMenu.removeAttribute('open');
  });
});
