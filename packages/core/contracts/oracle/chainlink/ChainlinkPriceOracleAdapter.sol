pragma solidity ^0.6.0;

import "../interfaces/OracleInterface.sol";
import "../interfaces/IdentifierWhitelistInterface.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainlinkPriceOracleAdapter is OracleInterface, IdentifierWhitelistInterface, ChainlinkClient, Ownable {
    struct OracleData {
        address _address;
        bool isAggregator;
        bytes32 jobId;
        bool disabled;
    }

    struct PriceFeed {
        mapping(uint256 => OracleData) oracles;
        uint256 currentOracle;

        mapping(uint256 => int256) priceData;
    }

    mapping(bytes32 => PriceFeed) public priceFeeds;

    mapping(address => bool) private requesters;

    modifier onlyRequester() {
        require(requesters[msg.sender], "Not authorized to initiate a request");
        _;
    }

    event NewPrice(bytes32 indexed identifier, uint256 time, int256 price);
    event OracleAdded(bytes32 indexed identifier, address oracleAddress);
    event OracleRemoved(bytes32 indexed identifier);

    constructor() public Ownable() {
        // TODO(mori) migrate chainlink token as well
        //setPublicChainlinkToken();
    }

    function _getCurrentOracle(bytes32 identifier) internal view returns (OracleData storage) {
        PriceFeed storage feed = priceFeeds[identifier];
        return feed.oracles[feed.currentOracle];
    }

    function _setPrice(bytes32 identifier, uint256 time, int256 price) internal {
        priceFeeds[identifier].priceData[time] = price;
        emit NewPrice(identifier, time, price);
    }
    
    /**
     * @notice Enqueues a request (if a request isn't already present) for the given `identifier`, `time` pair.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     */
    function requestPrice(bytes32 identifier, uint256 time) public onlyRequester override {
        OracleData storage oracle = _getCurrentOracle(identifier);

        if (oracle.isAggregator) {
            _setPrice(identifier, time, AggregatorV2V3Interface(oracle._address).latestAnswer());
        } else {
            // make chainlink request
            // TODO(mori) Create callback fn
            revert("NOT IMPLEMENTED");
        }
    }

    /**
     * @notice Whether the price for `identifier` and `time` is available.
     * @dev Time must be in the past and the identifier must be supported.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return bool if the DVM has resolved to a price for the given identifier and timestamp.
     */
    function hasPrice(bytes32 identifier, uint256 time) public view override returns (bool) {
        return priceFeeds[identifier].priceData[time] != 0;
    }

    /**
     * @notice Gets the price for `identifier` and `time` if it has already been requested and resolved.
     * @dev If the price is not available, the method reverts.
     * @param identifier uniquely identifies the price requested. eg BTC/USD (encoded as bytes32) could be requested.
     * @param time unix timestamp for the price request.
     * @return int256 representing the resolved price for the given identifier and timestamp.
     */
    function getPrice(bytes32 identifier, uint256 time) public view override returns (int256) {
        return priceFeeds[identifier].priceData[time];
    }

    /**
     * @notice Adds the provided identifier as a supported identifier.
     * @dev Price requests using this identifier will succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function addSupportedIdentifier(bytes32 identifier) public onlyOwner() override {
        revert("Not implemented. Please use `addOracle` instead.");
    }

    /**
     * @notice Removes the identifier from the whitelist.
     * @dev Price requests using this identifier will no longer succeed after this call.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     */
    function removeSupportedIdentifier(bytes32 identifier) public onlyOwner() override {
        revert("Not implemented. Please use `removeOracle` instead.");
    }


    function addOracle(bytes32 identifier, address oracleAddress, bool isAggregator, bytes32 jobId) public onlyOwner() {
        OracleData memory newOracle = OracleData({
            _address: oracleAddress,
            isAggregator: isAggregator,
            jobId: jobId,
            disabled: false
        });

        PriceFeed storage feed = priceFeeds[identifier];

        feed.oracles[feed.currentOracle + 1] = newOracle;
        feed.currentOracle++;

        emit OracleAdded(identifier, oracleAddress);
    }


    function removeOracle(bytes32 identifier) public onlyOwner() {
        PriceFeed storage feed = priceFeeds[identifier];
        feed.oracles[feed.currentOracle].disabled = true;
        emit OracleRemoved(identifier);
    }

    /**
     * @notice Checks whether an identifier is on the whitelist.
     * @param identifier bytes32 encoding of the string identifier. Eg: BTC/USD.
     * @return bool if the identifier is supported (or not).
     */
    function isIdentifierSupported(bytes32 identifier) external view override returns (bool) {
        OracleData memory oracle = _getCurrentOracle(identifier);
        return oracle._address != address(0) && !oracle.disabled;
    }
}