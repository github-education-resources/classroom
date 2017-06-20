function offsetToTimezoneString(offset){
  var sign = offset > 0 ? "-" : "+";
  var offsetString = String(Math.abs(offset))
  var paddedString = offsetString.length == 1 ? "0" + offsetString : offsetString;

  return sign + paddedString + "00";
}

function leftpad(val){
  return ("0" + val).slice(-2);
}

function initializePicker(picker){
  if($(picker).val() !== ""){
    var d = new Date($(picker).val() + " UTC");
    var dateString = leftpad(d.getMonth()+1)
                       + "/"
                       + leftpad(d.getDate())
                       + "/"
                       + d.getFullYear()
                       + " "
                       + leftpad(d.getHours())
                       + ":"
                       + leftpad(d.getMinutes())
                       + " "
                       + offsetToTimezoneString(d.getTimezoneOffset()/60);

    $(picker)[0].value = dateString;
  }

  $(picker).datetimepicker({
    format: 'm/d/Y H:i O'
  });
}

$('.jquery-datetimepicker').each(function(){
  initializePicker(this);
});

// Since turbolinks dynamically loads pages, we can't just run JS on page load to initialize datepickers
// This observer listens for when the body is re-added to the DOM, which is how turbolinks updates
// Then we search the body for any new datetimepickers.
var config = { attributes: true, childList: true, subtree: true, characterData: true };
var observer = new MutationObserver(function(mutations) {
  mutations.forEach(function(mutation) {
    for(var i = 0; i < mutation.addedNodes.length; i++){
      if(mutation.addedNodes[i].nodeName.toLowerCase() == "body"){
        var body = mutation.addedNodes[i];
        $(body).find(".jquery-datetimepicker").each(function(){
          initializePicker(this);
        })
      }
    }
  });
});

observer.observe(document, config);
