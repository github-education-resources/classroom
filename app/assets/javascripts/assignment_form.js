function import_options(starter_code_field_value) {
  if (starter_code_field_value.length > 0) {
    document.getElementById('import-options').style.display ="";
  } else {
    document.getElementById('import-options').style.display ="none";
  }
}
