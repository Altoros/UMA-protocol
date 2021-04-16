const {
    contract as clContract,
    helpers as h,
    matchers,
    setup,
    wallet,
  } = require('@chainlink/test-helpers')
const { assert } = require('chai')

const web3 = require('web3')

const ChainlinkPriceOracleAdapter = artifacts.require("ChainlinkPriceOracleAdapter")
const MockChainlinkOracle = artifacts.require("MockChainlinkOracle")

contract("ChainlinkPriceOracleAdapter", ([deployer, alice, bob]) => {
    before(async () => {
        const tokenFactory = new clContract.LinkTokenFactory()
        this.token = await tokenFactory.connect(deployer).deploy()

        this.mockOracle = await MockChainlinkOracle.new(
            this.token.address
        )

        this.adapter = await ChainlinkPriceOracleAdapter.new()

        this.identifier = web3.utils.fromAscii("TEST")
        this.jobID = web3.utils.fromAscii("TEST_JOB_ID")

        await this.identifier.addOracle(
            this.identifier,
            this.mockOracle.address,
            false,
            this.jobID,
            web3.utils.toWei(1, 'wei')
        )
    })

    it("should make requests to the oracle", async () => {
        await this.mockOracle.setPrice(100)

        await this.adapter.requestPrice(
            this.identifier,
            0
        )

        const response = await this.adapter.getPrice(
            this.identifier,
            0
        )

        assert(response.equals(100), "wrong price returned")
    })
})