var Contribution = artifacts.require("./Contribution.sol")
var CGXMultiSigWallet = artifacts.require("./CGXMultiSigWallet.sol")

var pubstartTime = 150020;

var cgcx_company_account = '0x0046843B90245990b0FE57bDCbfb701d28AFf168';
var signers = ['0x0037efE694c4a97376E563b5D1DE1457CF9619Fb', '0x009393Ff2AF09d7D8e6496989Be6882e1968EA6d', '0x0046843B90245990b0FE57bDCbfb701d28AFf168'];

module.exports = function(deployer) {

  console.log("\nDeployment:\nPublic Start Time " + pubstartTime);

  deployer.deploy(CGXMultiSigWallet, signers, 2)
	.then(function() {
	  return deployer.deploy(Contribution,
	  	CGXMultiSigWallet.address,
	  	cgcx_company_account,
	  	pubstartTime);
	})
};
