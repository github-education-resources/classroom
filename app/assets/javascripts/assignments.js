$('.assignments').ready(function() { 
    $(".assignments #js-search-form").on("keyup", function(e) {
        var $queryField = $(e.target);
        var $sortMenu = $(".select-menu");
        var query = $queryField.val();

        var currentLinks = $sortMenu[0].getOptionLinks();
        var newLinks = currentLinks.map(link => {
            newLink = new URLSearchParams(link);
            newLink.set("query", query);

            return newLink.toString();
        });

        $sortMenu[0].setOptionLinks(newLinks);
    });
});
