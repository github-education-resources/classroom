function importOptions(starterCodeFieldValue) {
  const importOptions = document.getElementById('import-options');
  if (starterCodeFieldValue.length > 0) {
    importOptions.style.display = '';
  } else {
    importOptions.style.display = 'none';
  }
}

function removeErrorBox(el) {
  var parent = el.closest(".errored");

  if (!parent) return;

  var errorBox = parent.querySelector(".error");

  parent.classList.remove("errored");
  errorBox && errorBox.remove();
}
