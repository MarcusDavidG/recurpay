// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SubscriptionEvents {
    // Core subscription events
    event SubscriptionCreated(bytes32 indexed subscriptionId, address indexed creator, address indexed subscriber);
    event SubscriptionCancelled(bytes32 indexed subscriptionId, address indexed subscriber, string reason);
    event SubscriptionPaused(bytes32 indexed subscriptionId, address indexed subscriber, uint256 duration);
    event SubscriptionResumed(bytes32 indexed subscriptionId, address indexed subscriber);
    event SubscriptionExpired(bytes32 indexed subscriptionId, address indexed subscriber);

    // Payment events
    event PaymentProcessed(bytes32 indexed subscriptionId, uint256 amount, address indexed payer);
    event PaymentFailed(bytes32 indexed subscriptionId, uint256 amount, string reason);
    event PaymentRetried(bytes32 indexed subscriptionId, uint256 attemptNumber);
    event RefundIssued(bytes32 indexed subscriptionId, uint256 amount, address indexed recipient);

    // Plan events
    event PlanCreated(uint256 indexed planId, address indexed creator, uint256 price);
    event PlanUpdated(uint256 indexed planId, uint256 newPrice, uint256 newDuration);
    event PlanDeactivated(uint256 indexed planId, address indexed creator);

    // Tier events
    event TierCreated(address indexed creator, uint256 indexed tierId, string name);
    event TierUpgraded(bytes32 indexed subscriptionId, uint256 fromTier, uint256 toTier);
    event TierDowngraded(bytes32 indexed subscriptionId, uint256 fromTier, uint256 toTier);

    // Discount events
    event DiscountApplied(bytes32 indexed subscriptionId, string discountCode, uint256 amount);
    event DiscountCreated(bytes32 indexed discountId, string code, uint256 percentage);
    event DiscountExpired(bytes32 indexed discountId, string code);

    // Referral events
    event ReferralRegistered(address indexed referrer, address indexed referred);
    event ReferralRewardPaid(address indexed referrer, uint256 amount);

    // Analytics events
    event MetricRecorded(address indexed creator, string metricName, uint256 value);
    event RevenueGenerated(address indexed creator, uint256 amount, string source);
    event ChurnRecorded(address indexed creator, bytes32 indexed subscriptionId, string reason);

    function emitSubscriptionCreated(bytes32 subscriptionId, address creator, address subscriber) external {
        emit SubscriptionCreated(subscriptionId, creator, subscriber);
    }

    function emitPaymentProcessed(bytes32 subscriptionId, uint256 amount, address payer) external {
        emit PaymentProcessed(subscriptionId, amount, payer);
    }

    function emitPlanCreated(uint256 planId, address creator, uint256 price) external {
        emit PlanCreated(planId, creator, price);
    }

    function emitMetricRecorded(address creator, string memory metricName, uint256 value) external {
        emit MetricRecorded(creator, metricName, value);
    }
}
