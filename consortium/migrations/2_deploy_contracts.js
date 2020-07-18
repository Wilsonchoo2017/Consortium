var Adoption = artifacts.require("Adoption");
var TenancyAgreementFactory = artifacts.require("TenancyAgreementFactory");

module.exports = function (deployer) {
  deployer.deploy(Adoption);
  deployer.deploy(TenancyAgreementFactory);
};
