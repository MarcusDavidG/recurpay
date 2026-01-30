// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionBridge {
    struct BridgeRequest {
        address user;
        uint256 subscriptionId;
        uint256 sourceChain;
        uint256 targetChain;
        bytes32 requestHash;
        bool processed;
    }

    mapping(bytes32 => BridgeRequest) public bridgeRequests;
    mapping(uint256 => bool) public supportedChains;
    mapping(address => bool) public validators;

    event BridgeInitiated(bytes32 indexed requestId, address user, uint256 sourceChain, uint256 targetChain);
    event BridgeCompleted(bytes32 indexed requestId);

    function initiateBridge(
        uint256 subscriptionId,
        uint256 targetChain
    ) external returns (bytes32 requestId) {
        require(supportedChains[targetChain], "Chain not supported");
        
        requestId = keccak256(abi.encodePacked(
            msg.sender,
            subscriptionId,
            block.chainid,
            targetChain,
            block.timestamp
        ));

        bridgeRequests[requestId] = BridgeRequest({
            user: msg.sender,
            subscriptionId: subscriptionId,
            sourceChain: block.chainid,
            targetChain: targetChain,
            requestHash: requestId,
            processed: false
        });

        emit BridgeInitiated(requestId, msg.sender, block.chainid, targetChain);
    }

    function completeBridge(bytes32 requestId, bytes memory proof) external {
        require(validators[msg.sender], "Not validator");
        
        BridgeRequest storage request = bridgeRequests[requestId];
        require(!request.processed, "Already processed");
        
        // Verify proof (simplified)
        require(proof.length > 0, "Invalid proof");
        
        request.processed = true;
        emit BridgeCompleted(requestId);
    }

    function addSupportedChain(uint256 chainId) external {
        supportedChains[chainId] = true;
    }

    function addValidator(address validator) external {
        validators[validator] = true;
    }
}
