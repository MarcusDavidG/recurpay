// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionUpgradeManager {
    struct UpgradeRequest {
        bytes32 subscriptionId;
        uint256 fromTierId;
        uint256 toTierId;
        uint256 requestedAt;
        uint256 effectiveDate;
        bool processed;
        bool isUpgrade;
        uint256 priceDifference;
        uint256 prorationAmount;
    }

    mapping(bytes32 => UpgradeRequest) public upgradeRequests;
    mapping(bytes32 => uint256) public currentTier;
    
    uint256 public upgradeRequestCounter;

    event UpgradeRequested(bytes32 indexed requestId, bytes32 indexed subscriptionId, uint256 fromTier, uint256 toTier);
    event UpgradeProcessed(bytes32 indexed requestId, bool success);
    event TierChanged(bytes32 indexed subscriptionId, uint256 newTierId);

    function requestUpgrade(
        bytes32 subscriptionId,
        uint256 toTierId,
        uint256 effectiveDate
    ) external returns (bytes32 requestId) {
        uint256 fromTierId = currentTier[subscriptionId];
        require(fromTierId != toTierId, "Same tier");
        require(effectiveDate >= block.timestamp, "Invalid effective date");

        requestId = keccak256(abi.encodePacked(
            subscriptionId,
            toTierId,
            block.timestamp,
            upgradeRequestCounter++
        ));

        bool isUpgrade = toTierId > fromTierId;
        uint256 priceDifference = calculatePriceDifference(fromTierId, toTierId);
        uint256 prorationAmount = calculateProration(subscriptionId, priceDifference, effectiveDate);

        upgradeRequests[requestId] = UpgradeRequest({
            subscriptionId: subscriptionId,
            fromTierId: fromTierId,
            toTierId: toTierId,
            requestedAt: block.timestamp,
            effectiveDate: effectiveDate,
            processed: false,
            isUpgrade: isUpgrade,
            priceDifference: priceDifference,
            prorationAmount: prorationAmount
        });

        emit UpgradeRequested(requestId, subscriptionId, fromTierId, toTierId);
    }

    function processUpgrade(bytes32 requestId) external payable {
        UpgradeRequest storage request = upgradeRequests[requestId];
        require(!request.processed, "Already processed");
        require(block.timestamp >= request.effectiveDate, "Not yet effective");

        if (request.isUpgrade && request.prorationAmount > 0) {
            require(msg.value >= request.prorationAmount, "Insufficient payment");
        }

        currentTier[request.subscriptionId] = request.toTierId;
        request.processed = true;

        emit UpgradeProcessed(requestId, true);
        emit TierChanged(request.subscriptionId, request.toTierId);
    }

    function cancelUpgradeRequest(bytes32 requestId) external {
        UpgradeRequest storage request = upgradeRequests[requestId];
        require(!request.processed, "Already processed");
        require(block.timestamp < request.effectiveDate, "Too late to cancel");

        request.processed = true; // Mark as processed to prevent execution
        emit UpgradeProcessed(requestId, false);
    }

    function calculatePriceDifference(uint256 fromTierId, uint256 toTierId) 
        internal 
        pure 
        returns (uint256) 
    {
        // Simplified calculation - would integrate with tier pricing
        if (toTierId > fromTierId) {
            return (toTierId - fromTierId) * 1e18; // Example: 1 ETH per tier difference
        } else {
            return (fromTierId - toTierId) * 1e18;
        }
    }

    function calculateProration(
        bytes32 subscriptionId,
        uint256 priceDifference,
        uint256 effectiveDate
    ) internal view returns (uint256) {
        // Simplified proration calculation
        uint256 remainingDays = getRemainingDays(subscriptionId);
        uint256 totalDays = 30; // Assuming monthly subscriptions
        
        return (priceDifference * remainingDays) / totalDays;
    }

    function getRemainingDays(bytes32 subscriptionId) internal pure returns (uint256) {
        // Simplified - would calculate actual remaining days
        return 15; // Example: 15 days remaining
    }

    function getUpgradeRequest(bytes32 requestId) external view returns (UpgradeRequest memory) {
        return upgradeRequests[requestId];
    }

    function getCurrentTier(bytes32 subscriptionId) external view returns (uint256) {
        return currentTier[subscriptionId];
    }

    function getPendingUpgrades(bytes32 subscriptionId) external view returns (bytes32[] memory) {
        // This would return all pending upgrade requests for a subscription
        // Simplified implementation
        bytes32[] memory pending = new bytes32[](0);
        return pending;
    }
}
