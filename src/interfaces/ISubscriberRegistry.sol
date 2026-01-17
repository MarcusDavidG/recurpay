// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ISubscriberRegistry
/// @author RecurPay Protocol
/// @notice Interface for tracking subscription state and subscriber data on Base
interface ISubscriberRegistry {
    // =========================================================================
    // Enums
    // =========================================================================

    /// @notice Subscription lifecycle status
    enum SubscriptionStatus {
        None,       // Subscription does not exist
        Active,     // Subscription is active and in good standing
        Paused,     // Subscriber has paused the subscription
        GracePeriod,// Payment failed, in grace period
        Cancelled,  // Subscription has been cancelled
        Expired     // Subscription expired (non-renewal)
    }

    // =========================================================================
    // Structs
    // =========================================================================

    /// @notice Core subscription data
    /// @param id Unique subscription identifier
    /// @param planId Associated subscription plan
    /// @param subscriber Subscriber address
    /// @param status Current subscription status
    /// @param startDate Subscription start timestamp
    /// @param currentPeriodStart Start of current billing period
    /// @param currentPeriodEnd End of current billing period
    /// @param lastPaymentDate Last successful payment timestamp
    /// @param totalPaid Total amount paid over subscription lifetime
    struct Subscription {
        uint256 id;
        uint256 planId;
        address subscriber;
        SubscriptionStatus status;
        uint64 startDate;
        uint64 currentPeriodStart;
        uint64 currentPeriodEnd;
        uint64 lastPaymentDate;
        uint64 pausedUntil;
        uint256 totalPaid;
    }

    /// @notice Subscriber profile data
    /// @param subscriptionCount Total subscriptions (active + inactive)
    /// @param activeSubscriptions Current active subscription count
    /// @param totalSpent Total amount spent across all subscriptions
    /// @param firstSubscriptionDate Date of first subscription
    struct SubscriberProfile {
        uint32 subscriptionCount;
        uint32 activeSubscriptions;
        uint256 totalSpent;
        uint64 firstSubscriptionDate;
    }

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a new subscription is created
    /// @param subscriptionId Unique subscription identifier
    /// @param planId Associated plan
    /// @param subscriber Subscriber address
    /// @param creator Plan creator address
    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        uint256 indexed planId,
        address indexed subscriber,
        address creator
    );

    /// @notice Emitted when subscription status changes
    /// @param subscriptionId Subscription identifier
    /// @param oldStatus Previous status
    /// @param newStatus New status
    event SubscriptionStatusChanged(
        uint256 indexed subscriptionId,
        SubscriptionStatus oldStatus,
        SubscriptionStatus newStatus
    );

    /// @notice Emitted when subscriber pauses subscription
    /// @param subscriptionId Subscription identifier
    /// @param pausedUntil Timestamp when pause ends (0 for indefinite)
    event SubscriptionPaused(uint256 indexed subscriptionId, uint64 pausedUntil);

    /// @notice Emitted when subscriber resumes subscription
    /// @param subscriptionId Subscription identifier
    event SubscriptionResumed(uint256 indexed subscriptionId);

    /// @notice Emitted when subscription is cancelled
    /// @param subscriptionId Subscription identifier
    /// @param reason Cancellation reason code
    /// @param refundAmount Refund amount (if applicable)
    event SubscriptionCancelled(
        uint256 indexed subscriptionId,
        bytes4 reason,
        uint256 refundAmount
    );

    /// @notice Emitted when subscription period is renewed
    /// @param subscriptionId Subscription identifier
    /// @param newPeriodEnd New period end timestamp
    event SubscriptionRenewed(uint256 indexed subscriptionId, uint64 newPeriodEnd);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Thrown when subscription does not exist
    error SubscriptionNotFound();

    /// @notice Thrown when caller is not the subscriber
    error NotSubscriber();

    /// @notice Thrown when subscription is not active
    error SubscriptionNotActive();

    /// @notice Thrown when subscription is already cancelled
    error AlreadyCancelled();

    /// @notice Thrown when subscription is already paused
    error AlreadyPaused();

    /// @notice Thrown when subscription is not paused
    error NotPaused();

    /// @notice Thrown when subscriber already has active subscription to plan
    error AlreadySubscribed();

    /// @notice Thrown when plan has reached max subscribers
    error PlanAtCapacity();

    // =========================================================================
    // Functions
    // =========================================================================

    /// @notice Creates a new subscription
    /// @param planId Plan to subscribe to
    /// @param subscriber Subscriber address
    /// @return subscriptionId New subscription identifier
    function subscribe(
        uint256 planId,
        address subscriber
    ) external returns (uint256 subscriptionId);

    /// @notice Pauses a subscription
    /// @param subscriptionId Subscription to pause
    /// @param pauseDuration Duration to pause (0 for indefinite)
    function pause(uint256 subscriptionId, uint32 pauseDuration) external;

    /// @notice Resumes a paused subscription
    /// @param subscriptionId Subscription to resume
    function resume(uint256 subscriptionId) external;

    /// @notice Cancels a subscription
    /// @param subscriptionId Subscription to cancel
    function cancel(uint256 subscriptionId) external;

    /// @notice Updates subscription status (called by payment processor)
    /// @param subscriptionId Subscription to update
    /// @param newStatus New status
    function updateStatus(uint256 subscriptionId, SubscriptionStatus newStatus) external;

    /// @notice Records a successful payment and renews period
    /// @param subscriptionId Subscription that was paid
    /// @param amount Payment amount
    function recordPayment(uint256 subscriptionId, uint256 amount) external;

    /// @notice Gets subscription details
    /// @param subscriptionId Subscription identifier
    /// @return subscription Subscription data
    function getSubscription(
        uint256 subscriptionId
    ) external view returns (Subscription memory subscription);

    /// @notice Gets all subscriptions for a subscriber
    /// @param subscriber Subscriber address
    /// @return subscriptionIds Array of subscription IDs
    function getSubscriberSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds);

    /// @notice Gets all active subscriptions for a subscriber
    /// @param subscriber Subscriber address
    /// @return subscriptionIds Array of active subscription IDs
    function getActiveSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds);

    /// @notice Gets subscriber profile
    /// @param subscriber Subscriber address
    /// @return profile Subscriber profile data
    function getSubscriberProfile(
        address subscriber
    ) external view returns (SubscriberProfile memory profile);

    /// @notice Gets all subscribers for a plan
    /// @param planId Plan identifier
    /// @return subscribers Array of subscriber addresses
    function getPlanSubscribers(
        uint256 planId
    ) external view returns (address[] memory subscribers);

    /// @notice Gets subscription count for a plan
    /// @param planId Plan identifier
    /// @return count Active subscriber count
    function getPlanSubscriberCount(uint256 planId) external view returns (uint256 count);

    /// @notice Checks if address has active subscription to plan
    /// @param subscriber Subscriber address
    /// @param planId Plan identifier
    /// @return isActive Whether subscription is active
    function hasActiveSubscription(
        address subscriber,
        uint256 planId
    ) external view returns (bool isActive);

    /// @notice Returns total number of subscriptions created
    /// @return count Total subscription count
    function totalSubscriptions() external view returns (uint256 count);
}
