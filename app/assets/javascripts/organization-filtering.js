$(document).ready(function() {
  const debounce = (() => {
    let timeoutId = null;
    return (callback, ms) => {
      if(timeoutId) {
        clearTimeout(timeoutId);
      }
      timeoutId = setTimeout(callback, ms);
    }
  })();

  $("#js-filtering-form").on("change keyup input", function(e) {
    const searchForm = e.currentTarget;
    const formData = $(searchForm).serialize();

    history.replaceState(null, '', '?' + formData);
    debounce(() => submitSearchAndFilters(searchForm), 150)
  });
});

function submitSearchAndFilters(form) {
    // Can't use .submit() here as it does not make request via XHR
    form.dispatchEvent(new CustomEvent('submit', {bubbles: true, cancelable: true}));
}