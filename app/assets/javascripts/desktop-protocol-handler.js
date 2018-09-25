(function() {

  var timeIndex;

  window.addEventListener("blur", function(e)
  {
    clearTimeout(timeIndex);
  });

  $("#js-download-repos-btn").click(function(e)
  {
    displayDownloadMessage();
  });

  $("#js-assistant-open-btn").click(function(e)
  {
    e.preventDefault();

    var el = $(this);
    var iFrame = $('#js-hidden-iframe')[0];

    timeIndex = setTimeout(function() {
      window.location = "http://www.classroom.github.com/assistant";
    }, 3000);

    // attempt to open deep link in iframe to avoid exposing link to user
    iFrame.contentWindow.location.href = el.attr("href");
    displayLaunchingMessage();
  });
}).call(this);

function displayLaunchingMessage() {
  var launchMessage = $('#js-modal-launching')[0];
  var downloadReposMessage = $('#js-modal-download-repos')[0];
  launchMessage.style.display = "block";
  downloadReposMessage.style.display = "none";
}

function displayDownloadMessage() {
  var launchMessage = $('#js-modal-launching')[0];
  var downloadReposMessage = $('#js-modal-download-repos')[0];
  launchMessage.style.display = "none";
  downloadReposMessage.style.display = "block";
}