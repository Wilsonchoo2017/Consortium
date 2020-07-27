//https://stackoverflow.com/questions/5942105/jquery-get-request-on-http-url
//Listen when a button, with a class of "myButton", is clicked
//You can use any jQuery/JavaScript event that you'd like to trigger the call
$('.checkPermissionButton').click(function() {
    //Send the AJAX call to the server
      $.ajax({
      //The URL to process the request
        url : 'http://127.0.0.1:8545',
      //The type of request, also known as the "method" in HTML forms
      //Can be 'GET' or 'POST'
        type : 'POST',
        dataType: 'json',
      //Any post-data/get-data parameters
      //This is optional
        data : JSON.stringify({ "jsonrpc" : "2.0", "method" : "net_peerCount", "params": [], "id": "53" }),
      //The response from the server
        'success' : function(data) {
        //You can use any jQuery/JavaScript here!!!
            alert(JSON.stringify(data.result))
        }
    });
});


$('.addTenantToNetworkButton').click(function() {

    //Send the AJAX call to the server
      $.ajax({
      //The URL to process the request
        url : 'http://127.0.0.1:8545',
      //The type of request, also known as the "method" in HTML forms
      //Can be 'GET' or 'POST'
        type : 'POST',
        dataType: 'json',
      //Any post-data/get-data parameters
      //This is optional
        data : JSON.stringify({ "jsonrpc" : "2.0", "method" : "perm_addAccountsToWhitelist", "params": [[currentAccount]], "id": 53 }),
      //The response from the server
        'success' : function(data) {
        //You can use any jQuery/JavaScript here!!!
            alert(JSON.stringify(data.result))
        },
        'error ': function (request, status, error) {
            alert(request.responseText);
        }
    });
});


let currentAccount = null;
ethereum
  .request({ method: 'eth_accounts' })
  .then(handleAccountsChanged)
  .catch((err) => {
    // Some unexpected error.
    // For backwards compatibility reasons, if no accounts are available,
    // eth_accounts will return an empty array.
    console.error(err);
  });

// Note that this event is emitted on page load.
// If the array of accounts is non-empty, you're already
// connected.
ethereum.on('accountsChanged', handleAccountsChanged);

// For now, 'eth_accounts' will continue to always return an array
function handleAccountsChanged(accounts) {
  if (accounts.length === 0) {
    // MetaMask is locked or the user has not connected any accounts
    console.log('Please connect to MetaMask.');
  } else if (accounts[0] !== currentAccount) {
    currentAccount = accounts[0];
    // Do any other work!
  }
}