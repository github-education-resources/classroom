(function() {
  $(document).ready(function() {
    var ready = function() {
      var timeIndex;

      window.addEventListener("blur", function(e) {
        clearTimeout(timeIndex);
      });

      $("#js-download-repos-btn").click(function(e) {
        displayDownloadMessage();
      });

      $("#js-assistant-open-btn").click(function(e) {
        displayLaunchingMessage();

        var isSafari = window.safari !== undefined;
        if (!isSafari) {
          e.preventDefault();
          var el = $(this);
          var iFrame = $("#js-hidden-iframe")[0];

          timeIndex = setTimeout(function() {
            window.location = "/assistant";
          }, 5000);

          // attempt to open deep link in iframe to avoid exposing link to user
          iFrame.contentWindow.location.href = el.attr("href");
        }
      });
    };
    $(document).ready(ready);
  });
}.call(this));

function displayLaunchingMessage() {
  var launchMessage = $("#js-modal-launching")[0];
  var downloadReposMessage = $("#js-modal-download-repos")[0];
  launchMessage.style.display = "block";
  downloadReposMessage.style.display = "none";
}

function displayDownloadMessage() {
  var launchMessage = $("#js-modal-launching")[0];
  var downloadReposMessage = $("#js-modal-download-repos")[0];
  launchMessage.style.display = "none";
  downloadReposMessage.style.display = "block";
}
