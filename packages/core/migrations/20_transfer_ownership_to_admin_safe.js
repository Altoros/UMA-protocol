const Finder = artifacts.require("Finder");
const Store = artifacts.require("Store");
const Registry = artifacts.require("Registry");
const AddressWhitelist = artifacts.require("AddressWhitelist")

const ChainlinkPriceOracleAdapter = artifacts.require("ChainlinkPriceOracleAdapter")

const { getKeysForNetwork, PublicNetworks } = require("@uma/common");

module.exports = async function(deployer, network, accounts) {
  const keys = getKeysForNetwork(network, accounts);

  const finder = await Finder.deployed()
  const registry = await Registry.deployed()
  const store = await Store.deployed()
  const oracleAdapter = await ChainlinkPriceOracleAdapter.deployed()
  const addressWhitelist = await AddressWhitelist.deployed()

  let adminSafe = null;

  for (const { name, adminSafeAddress } of Object.values(PublicNetworks)) {
    if (network.startsWith(name) && adminSafeAddress) {
      adminSafe = adminSafeAddress;
      break;
    }
  }

  if (adminSafe) {
    await finder.transferOwnership(adminSafeAddress, { from: keys.deployer })
    await registry.transferOwnership(adminSafeAddress, { from: keys.deployer })
    await store.transferOwnership(adminSafeAddress, { from: keys.deployer })
    await oracleAdapter.transferOwnership(adminSafeAddress, { from: keys.deployer })
    await addressWhitelist.transferOwnership(adminSafeAddress, { from: keys.deployer })
  }
}