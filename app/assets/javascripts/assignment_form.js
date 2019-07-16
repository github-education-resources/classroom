function importOptions(starterCodeFieldValue) {
  const importOptions = document.getElementById('import-options');
  if (starterCodeFieldValue.length > 0) {
    importOptions.style.display = '';
  } else {
    importOptions.style.display = 'none';
  }
}
