var TenancyAgreementFactory = artifacts.require("TenancyAgreementFactory");

module.exports = function(deployer) {
  deployer.deploy(TenancyAgreementFactory,1, "0x627306090abaB3A6e1400e9345bC60c78a8BEf57");
};

var ERC20 = artifacts.require("ERC20");

module.exports = function(deployer) {
  deployer.deploy(ERC20, "hello?", "0xFE3B557E8Fb62b89F4916B721be55cEb828dBd73");
};
