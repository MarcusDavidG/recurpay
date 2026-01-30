// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionPauseManager {
    struct PauseData {
        bool isPaused;
        uint256 pausedAt;
        uint256 pauseDuration;
        uint256 maxPauseDuration;
        uint256 totalPausedTime;
        string reason;
    }

    mapping(bytes32 => PauseData) public pausedSubscriptions;
    mapping(address => uint256) public maxPauseDurationByCreator;

    uint256 public constant DEFAULT_MAX_PAUSE_DURATION = 90 days;

    event SubscriptionPaused(bytes32 indexed subscriptionId, address indexed subscriber, string reason);
    event SubscriptionResumed(bytes32 indexed subscriptionId, address indexed subscriber);

    function pauseSubscription(
        bytes32 subscriptionId,
        uint256 pauseDuration,
        string memory reason
    ) external {
        PauseData storage pauseData = pausedSubscriptions[subscriptionId];
        require(!pauseData.isPaused, "Already paused");
        
        address creator = getCreatorFromSubscriptionId(subscriptionId);
        uint256 maxDuration = maxPauseDurationByCreator[creator] > 0 
            ? maxPauseDurationByCreator[creator] 
            : DEFAULT_MAX_PAUSE_DURATION;
            
        require(pauseDuration <= maxDuration, "Pause duration too long");

        pauseData.isPaused = true;
        pauseData.pausedAt = block.timestamp;
        pauseData.pauseDuration = pauseDuration;
        pauseData.maxPauseDuration = maxDuration;
        pauseData.reason = reason;

        emit SubscriptionPaused(subscriptionId, msg.sender, reason);
    }

    function resumeSubscription(bytes32 subscriptionId) external {
        PauseData storage pauseData = pausedSubscriptions[subscriptionId];
        require(pauseData.isPaused, "Not paused");

        uint256 pausedTime = block.timestamp - pauseData.pausedAt;
        pauseData.totalPausedTime += pausedTime;
        pauseData.isPaused = false;
        pauseData.pausedAt = 0;

        emit SubscriptionResumed(subscriptionId, msg.sender);
    }

    function isSubscriptionPaused(bytes32 subscriptionId) external view returns (bool) {
        PauseData memory pauseData = pausedSubscriptions[subscriptionId];
        
        if (!pauseData.isPaused) return false;
        
        // Auto-resume if pause duration exceeded
        if (block.timestamp >= pauseData.pausedAt + pauseData.pauseDuration) {
            return false;
        }
        
        return true;
    }

    function getRemainingPauseTime(bytes32 subscriptionId) external view returns (uint256) {
        PauseData memory pauseData = pausedSubscriptions[subscriptionId];
        
        if (!pauseData.isPaused) return 0;
        
        uint256 elapsed = block.timestamp - pauseData.pausedAt;
        if (elapsed >= pauseData.pauseDuration) return 0;
        
        return pauseData.pauseDuration - elapsed;
    }

    function setMaxPauseDuration(uint256 duration) external {
        require(duration <= 365 days, "Duration too long");
        maxPauseDurationByCreator[msg.sender] = duration;
    }

    function getPauseData(bytes32 subscriptionId) external view returns (PauseData memory) {
        return pausedSubscriptions[subscriptionId];
    }

    // Helper function - would be implemented based on subscription ID structure
    function getCreatorFromSubscriptionId(bytes32 subscriptionId) internal pure returns (address) {
        // Extract creator address from subscription ID
        return address(uint160(uint256(subscriptionId) >> 96));
    }
}
