(function() {

  var timeIndex, url

  window.addEventListener("blur", function(e)
  {
    console.log("Redirected to app")
    clearTimeout(timeIndex)
    // window.location = url
  });

  $("a[href*='/desktop']").click(function(e)
  {
    e.preventDefault();

    var iFrame = $('#hiddenIframe')[0];
    var el = $(this);
    url = el.attr("href")

    timeIndex = setTimeout(function() {
      window.location = "https://desktop.github.com/";
    }, 1000);

    // attempt to open deep link in iframe to avoid exposing link to user
    iFrame.contentWindow.location.href = url
  });
}).call(this);
