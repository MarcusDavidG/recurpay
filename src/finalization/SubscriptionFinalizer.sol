// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionFinalizer {
    bool public finalized;
    address public finalizer;
    uint256 public finalizedAt;

    event ProtocolFinalized(address indexed finalizer, uint256 timestamp);

    modifier onlyFinalizer() {
        require(msg.sender == finalizer, "Not finalizer");
        _;
    }

    constructor() {
        finalizer = msg.sender;
    }

    function finalizeProtocol() external onlyFinalizer {
        require(!finalized, "Already finalized");
        
        finalized = true;
        finalizedAt = block.timestamp;
        
        emit ProtocolFinalized(msg.sender, block.timestamp);
    }

    function isFinalized() external view returns (bool) {
        return finalized;
    }
}
