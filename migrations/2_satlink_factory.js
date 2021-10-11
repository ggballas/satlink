const SatLinkFactory = artifacts.require("SatLinkFactory");

module.exports = function (deployer) {
  deployer.deploy(SatLinkFactory);
};