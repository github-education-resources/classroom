function importOptions(starterCodeFieldValue) {
  const importOptions = document.getElementById('import-options');
  if (starterCodeFieldValue.length > 0) {
    importOptions.style.display = '';
  } else {
    importOptions.style.display = 'none';
  }
}

function removeErrorBox(el) {
  parent = el.closest(".errored");

  if (!parent) return;

  errorBoxes = parent.getElementsByClassName("error");

  parent.classList.remove("errored");
  errorBoxes.length && errorBoxes[0].remove();
}
