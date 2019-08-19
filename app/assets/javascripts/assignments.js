function showLoadingIndicator(showIndicator) {
  const loadingIndicator = document.getElementById('loading-indicator');
  loadingIndicator.style.display = (showIndicator ? '' : 'none')
}

function showCheckmark(showCheckmark) {
  const checkmark = document.getElementById('checkmark');
  checkmark.style.display = (showCheckmark ? '' : 'none')
}
