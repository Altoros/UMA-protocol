const ChainlinkPriceOracleAdapter = artifacts.require("ChainlinkPriceOracleAdapter");
const { getKeysForNetwork } = require("@uma/common");
const identifiers = require("../config/xdai-identifiers");

module.exports = async function(deployer, network, accounts) {
  const keys = getKeysForNetwork(network, accounts);

  const supportedIdentifiers = await ChainlinkPriceOracleAdapter.deployed();

  for (const identifier of Object.keys(identifiers)) {
    const oracleData = identifiers[identifier]
    const identifierBytes = web3.utils.utf8ToHex(identifier);
    // await supportedIdentifiers.addSupportedIdentifier(identifierBytes, { from: keys.deployer });
    await supportedIdentifiers.addOracle(
      identifierBytes,
      oracleData.address,
      oracleData.isAggregator,
      oracleData.jobId || web3.utils.utf8ToHex("")
    )
  }
};
