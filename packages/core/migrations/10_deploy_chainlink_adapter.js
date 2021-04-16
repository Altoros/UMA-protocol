const ChainlinkPriceOracleAdapter = artifacts.require("ChainlinkPriceOracleAdapter")
const Finder = artifacts.require("Finder")
const AddressWhitelist = artifacts.require("AddressWhitelist");

const { deploy, getKeysForNetwork, interfaceName } = require("@uma/common");

module.exports = async function(deployer, network, accounts) {
  const keys = getKeysForNetwork(network, accounts);
  const finder = await Finder.deployed();

  const { contract: oracleAdapter } = await deploy(
    deployer,
    network,
    ChainlinkPriceOracleAdapter,
    { from: keys.deployer }
  )

  await finder.changeImplementationAddress(web3.utils.utf8ToHex(interfaceName.Oracle), oracleAdapter.address, {
    from: keys.deployer
  });
  await finder.changeImplementationAddress(
    web3.utils.utf8ToHex(interfaceName.IdentifierWhitelist),
    oracleAdapter.address,
    {
      from: keys.deployer
    }
  );

  // if (network.startsWith("xdai")) {
  //   // Add WXDAI to the list of supported identifiers and collaterals
  //   await oracleAdapter.addSupportedIdentifier("WXDAI_USD")
  // }
};
