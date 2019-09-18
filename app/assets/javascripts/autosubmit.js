// /* @flow strict */

// // Form AutoSubmit Behavior
// //
// // Automatically submits form when one of its fields change.
// //
// // Examples
// //
// //   <form action="/subscribe" data-autosubmit>
// //     <input type=radio name=state value=1> Subscribe
// //     <input type=radio name=state value=0> Unsubscribe
// //   </form>

// (function() {
//   const autosubmits = document.querySelectorAll("[data-autosubmit")

//   autosubmits.forEach(function(elem) {
//     elem.addEventListener('change', function(event) {
//       event.preventDefault()

//       const searchForm = event.currentTarget.form
//       const $sortMenu = $(".select-menu")
//       const query = $("#your-classroom-filter").val();
//       // debugger
//       const formData = $('input[name!=utf8]').serialize()
//       history.replaceState(null, '', '?' + formData);




//       // debounce(function() { $searchForm.submit(); }, 300);


//       searchForm.submit()
//     })
//   })
// }).call(this)
