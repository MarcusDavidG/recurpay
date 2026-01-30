// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract PaymentRetryManager {
    struct RetryConfig {
        uint256 maxRetries;
        uint256 retryInterval;
        uint256 backoffMultiplier;
        bool exponentialBackoff;
    }

    struct RetryAttempt {
        uint256 attemptCount;
        uint256 nextRetryTime;
        uint256 lastAttemptTime;
        bool completed;
        string lastFailureReason;
    }

    mapping(bytes32 => RetryAttempt) public retryAttempts;
    mapping(address => RetryConfig) public retryConfigs;

    RetryConfig public defaultRetryConfig = RetryConfig({
        maxRetries: 3,
        retryInterval: 1 days,
        backoffMultiplier: 2,
        exponentialBackoff: true
    });

    event RetryScheduled(bytes32 indexed paymentId, uint256 nextRetryTime, uint256 attemptCount);
    event RetryCompleted(bytes32 indexed paymentId, bool success);

    function scheduleRetry(
        bytes32 paymentId,
        address creator,
        string memory failureReason
    ) external returns (bool shouldRetry) {
        RetryAttempt storage attempt = retryAttempts[paymentId];
        RetryConfig memory config = retryConfigs[creator].maxRetries > 0 
            ? retryConfigs[creator] 
            : defaultRetryConfig;

        if (attempt.attemptCount >= config.maxRetries) {
            return false;
        }

        attempt.attemptCount++;
        attempt.lastAttemptTime = block.timestamp;
        attempt.lastFailureReason = failureReason;

        uint256 interval = config.retryInterval;
        if (config.exponentialBackoff && attempt.attemptCount > 1) {
            interval = interval * (config.backoffMultiplier ** (attempt.attemptCount - 1));
        }

        attempt.nextRetryTime = block.timestamp + interval;

        emit RetryScheduled(paymentId, attempt.nextRetryTime, attempt.attemptCount);
        return true;
    }

    function isRetryDue(bytes32 paymentId) external view returns (bool) {
        RetryAttempt memory attempt = retryAttempts[paymentId];
        return !attempt.completed && 
               attempt.nextRetryTime > 0 && 
               block.timestamp >= attempt.nextRetryTime;
    }

    function markRetryCompleted(bytes32 paymentId, bool success) external {
        retryAttempts[paymentId].completed = true;
        emit RetryCompleted(paymentId, success);
    }

    function setRetryConfig(
        uint256 maxRetries,
        uint256 retryInterval,
        uint256 backoffMultiplier,
        bool exponentialBackoff
    ) external {
        retryConfigs[msg.sender] = RetryConfig({
            maxRetries: maxRetries,
            retryInterval: retryInterval,
            backoffMultiplier: backoffMultiplier,
            exponentialBackoff: exponentialBackoff
        });
    }

    function getRetryAttempt(bytes32 paymentId) external view returns (RetryAttempt memory) {
        return retryAttempts[paymentId];
    }
}
