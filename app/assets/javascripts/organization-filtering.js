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
});
