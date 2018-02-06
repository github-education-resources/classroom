function selectTab(element){
  studentsTab = document.getElementById('students-tab');
  unlinkedTab = document.getElementById('unlinked-tab');
  studentsSpan = document.getElementById('students-span');
  unlinkedSpan = document.getElementById('unlinked-span');

  if(element == studentsTab){
    studentsSpan.classList.remove("hidden-tab");
    unlinkedSpan.classList.add("hidden-tab");

    studentsTab.classList.add("selected");
    unlinkedTab.classList.remove("selected");
  }else{
    studentsSpan.classList.add("hidden-tab");
    unlinkedSpan.classList.remove("hidden-tab");

    studentsTab.classList.remove("selected");
    unlinkedTab.classList.add("selected");
  }
}
