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

    // Unset cookie
    document.cookie = "unlinkedSet=; expires=Thu, 18 Dec 2013 12:00:00 UTC; path=/";
  }else{
    studentsSpan.classList.add("hidden-tab");
    unlinkedSpan.classList.remove("hidden-tab");

    studentsTab.classList.remove("selected");
    unlinkedTab.classList.add("selected");

    document.cookie = "unlinkedSet=true; path=/";
  }
}

function setTabOnLoad(){
  if (document.cookie.indexOf('unlinkedSet=') != -1){
    unlinkedTab = document.getElementById('unlinked-tab');
    if (unlinkedTab !== null){
      selectTab(unlinkedTab);
    }
  }
}
