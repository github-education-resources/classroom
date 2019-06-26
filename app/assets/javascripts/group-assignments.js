$(".group_assignments").ready(function() { 
    $(".group_assignments #js-search-form").on("keyup", function(e) {
        var $queryField = $(e.target);
        var $sortMenu = $(".select-menu");
        var query = $queryField.val();

        var currentLinks = $sortMenu[0].getOptionLinks();
        var newLinks = currentLinks.map(link => {
            var url = new URL(link);
            var urlParams = new URLSearchParams(url.search.slice(1));
            urlParams.set("query", query);

            return "?" + urlParams.toString();
        });

        $sortMenu[0].setOptionLinks(newLinks);
    });
});
