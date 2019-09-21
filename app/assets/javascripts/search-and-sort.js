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
        var componentContext = $(e.target).closest("#js-search-and-sort-component");
        var $searchForm = componentContext.find("#search-form");
        var $sortMenu = componentContext.find(".select-menu")

        var query = $searchForm.find("#search-query-field").val();
        var currentLinks = $sortMenu[0].getOptionLinks();
        var newLinks = currentLinks.map(function(link) {
            var url = new URL(link);
            var urlParams = new URLSearchParams(url.search.slice(1));
            urlParams.set("query", query);

            return url.pathname + "?" + urlParams.toString();
        });
        $sortMenu[0].setOptionLinks(newLinks);

        formData = $searchForm.find('input[name!=utf8]').serialize();
        history.replaceState(null, '', '?' + formData);
        debounce(function() { $searchForm.submit(); }, 300);
    });

    $("#js-search-and-sort-component .select-menu").on("select", function(e) {
        var selectedItem = $(e.target);
        var componentContext = selectedItem.closest("#js-search-and-sort-component");

        componentContext.find("#sort-mode-field").val($.trim(selectedItem.text()));
    });
});
