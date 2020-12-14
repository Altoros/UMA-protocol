pragma solidity ^0.6.0;

import "@chainlink/contracts/src/v0.6/Oracle.sol";

contract MockChainlinkOracle is Oracle {
    uint256 public price;

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function oracleRequest(
        address _sender,
        uint256 _payment,
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        uint256 _nonce,
        uint256 _dataVersion,
        bytes memory _data
    )
    public
    override
    onlyLINK()
    checkCallbackAddress(_callbackAddress)
  {
        bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
        require(commitments[requestId] == 0, "Must use a unique ID");
        // solhint-disable-next-line not-rely-on-time
        uint256 expiration = now.add(EXPIRY_TIME);

        commitments[requestId] = keccak256(
            abi.encodePacked(
                _payment,
                _callbackAddress,
                _callbackFunctionId,
                expiration
            )
        );

        emit OracleRequest(
            _specId,
            _sender,
            requestId,
            _payment,
            _callbackAddress,
            _callbackFunctionId,
            expiration,
            _dataVersion,
            _data
        );

        fulfillOracleRequest(requestId, _payment, _callbackAddress, _callbackFunctionId, expiration, bytes32(price));
    }   
}