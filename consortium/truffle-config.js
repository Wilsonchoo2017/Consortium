
const PrivateKeyProvider = require("@truffle/hdwallet-provider");
const dotenv = require('dotenv');

dotenv.config();

/* The adress used when sending transactions to the node */
var address = process.env.BESU_NODE_PERM_ACCOUNT;

/* The private key associated with the address above */
var privateKey = process.env.BESU_NODE_PERM_KEY;

/* The endpoint of the Ethereum node */
var endpoint = process.env.BESU_NODE_PERM_ENDPOINT;
if (endpoint === undefined) {
  endpoint = "http://127.0.0.1:8545";
}

// insert the private key of the account used in metamask eg: Account 1 (Miner Coinbase Account)
const privateKeyProvider = new PrivateKeyProvider(privateKey, "http://127.0.0.1:8545");

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // for more about customizing your Truffle configuration!
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
      provider: () => new PrivateKeyProvider(privateKey, "http://localhost:8545"),
      from: address
    }
  },
  mocha: {
    enableTimeouts: false,
    before_timeout: 120000 // Here is 2min but can be whatever timeout is suitable for you.
  },
  compilers: {
    solc: {
      version: "^0.6.0" // A version or constraint - Ex. "^0.5.0"

    }
  }
};
