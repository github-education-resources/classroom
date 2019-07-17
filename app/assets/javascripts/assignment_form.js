function importOptions(starterCodeFieldValue) {
  const importOptions = document.getElementById('import-options');
  if (starterCodeFieldValue.length > 0) {
    importOptions.style.display = '';
  } else {
    importOptions.style.display = 'none';
  }
}

function removeErrorBox() {
  errorBoxes = document.getElementsByClassName("error");
  for (let errorBox of errorBoxes) {
    if (errorBox.innerText == "Starter code repository is not a template repository. Make it a template repository to use template cloning.") {
      errorBox.style.display = 'none';
    }
  }
}
