$(document).ready(function() {
    $("#repo-search-query-field").on("keyup", function(e) {
        var $queryField = $(e.target);
        var $sortMenu = $(".select-menu");
        var query = $queryField.val();

        var currentLinks = $sortMenu[0].getOptionLinks();
        var newLinks = currentLinks.map(function(link) {
            var url = new URL(link);
            var urlParams = new URLSearchParams(url.search.slice(1));
            urlParams.set("query", query);

            return "?" + urlParams.toString();
        });

        $sortMenu[0].setOptionLinks(newLinks);
    });
});
