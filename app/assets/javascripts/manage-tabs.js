//= require jquery/dist/jquery

// Takes in the id of an element containing tabs and content associated
// with each tab. Tabs are marked by clTabId and tab content by clContentId
function manageTabGroup(tab_group_id) {
  var tabGroup = $('#' + tab_group_id);
  var currentTabId;
  var tabGroupSaveId = 'CLTab-' + tab_group_id;

  function tabForId(tabId) {return $(tabGroup.find('[clTabId="' + tabId + '"]'));}
  function contentForId(contentId) {return $(tabGroup.find('[clContentId="' + contentId + '"]'));}
  function saveSelectedTab(tabId) { window.sessionStorage.setItem(tabGroupSaveId, tabId);}
  function retrieveSelectedTab() { return window.sessionStorage.getItem(tabGroupSaveId);}

  // Deselects old tab and selects new one
  function selectTab(tabId) {
    tabForId(currentTabId).removeClass('selected');
    contentForId(currentTabId).addClass('hidden-tab');
    tabForId(tabId).addClass('selected');
    contentForId(tabId).removeClass('hidden-tab');

    // Update currentTab tracking
    currentTabId = tabId;
    saveSelectedTab(tabId);
  }

  function setup() {
    // Start tracking currentTab, first trying to restore previously selected
    var previouslySelectedTab = retrieveSelectedTab();
    currentTabId = $(tabGroup.find('[clTabId].selected')).attr('clTabId');
    if (previouslySelectedTab) {
      selectTab(previouslySelectedTab);
    }

    // Find all children with tabIdx and add click handler
    tabGroup.find('[clTabId]').each(function() {
      $(this).click(function(e) {
        e.preventDefault();
        selectTab($(this).attr('clTabId'));
      });
    });
  }

  setup();
}

