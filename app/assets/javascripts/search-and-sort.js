$(document).ready(function() {
  var debounce = (function() {
    var timer;
    timer = 0;
    return function(callback, ms) {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(callback, ms);
    };
  })();

  $("#js-search-and-sort-component #search-query-field").on("keyup", function(e) {
    const componentContext = $(e.target).closest("#js-search-and-sort-component");
    const $searchForm = componentContext.find("#search-form");
    const $sortMenu = componentContext.find(".select-menu")

    const query = $searchForm.find("#search-query-field").val();
    const currentLinks = $sortMenu[0].getOptionLinks();
    const newLinks = currentLinks.map(function(link) {
      const url = new URL(link);
      const urlParams = new URLSearchParams(url.search.slice(1));
      urlParams.set("query", query);

      return url.pathname + "?" + urlParams.toString();
    });
    $sortMenu[0].setOptionLinks(newLinks);

    formData = $searchForm.find('input[name!=utf8]').serialize();
    history.replaceState(null, '', '?' + formData);
    debounce(function() { $searchForm.submit(); }, 300);
  });

  $("#js-search-and-sort-component .select-menu").on("select", function(e) {
    const selectedItem = $(e.target);
    const componentContext = selectedItem.closest("#js-search-and-sort-component");

    componentContext.find("#sort-mode-field").val($.trim(selectedItem.text()));
  });
});
