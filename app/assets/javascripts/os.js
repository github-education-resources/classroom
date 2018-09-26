(function() {

  var htmlElement = document.documentElement;

  if (navigator.platform.match(/(Mac|iPhone|iPod|iPad)/i)) {
    htmlElement.className = 'mac';
  } else if (navigator.platform.match(/Linux.*/i)) {
    htmlElement.className = 'linux';
  } else {
    htmlElement.className = 'windows';
  }

  document.addEventListener('click', function(event) {
    var target = event.target;
    if (target.getAttribute && target.getAttribute('data-action') === 'switch-os') {
      event.preventDefault();
      htmlElement.className = target.getAttribute('data-os');
    }
  });
})();
