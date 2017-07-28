function onIdentifiersUploaded(){
  var fileUploader = document.getElementById("file-upload");
  var entriesField = document.getElementById("entries-field");

  var file = fileUploader.files[0];
  var reader = new FileReader();

  reader.onload = function(e){
    var identifiers = e.target.result;
    entriesField.value += identifiers;
  };

  reader.readAsText(file);
}
