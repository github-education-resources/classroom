App.repository_creation_status = App.cable.subscriptions.create("RepositoryCreationStatusChannel", {
  connected: function() {
    // Called when the subscription is ready for use on the server
    console.log("==================\nCONECTED\n================")
  },

  disconnected: function() {
    // Called when the subscription has been terminated by the server
    console.log("=================+\nDISCONECTED\n=============")
  },

  received: function(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log(data)
  }
});
