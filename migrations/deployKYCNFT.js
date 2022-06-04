const KYCNFT = artifacts.require("KYCNFT");

module.exports = function (deployer) {
  deployer.deploy(KYCNFT);
};

