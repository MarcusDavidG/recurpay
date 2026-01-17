// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IPaymentProcessor
/// @author RecurPay Protocol
/// @notice Interface for processing recurring subscription payments on Base
interface IPaymentProcessor {
    // =========================================================================
    // Structs
    // =========================================================================

    /// @notice Payment execution details
    /// @param subscriptionId Subscription being charged
    /// @param amount Payment amount
    /// @param token Payment token address
    /// @param timestamp Execution timestamp
    /// @param success Whether payment succeeded
    struct PaymentExecution {
        uint256 subscriptionId;
        uint256 amount;
        address token;
        uint64 timestamp;
        bool success;
    }

    /// @notice Batch processing result
    /// @param processed Number of payments processed
    /// @param succeeded Number of successful payments
    /// @param failed Number of failed payments
    /// @param totalAmount Total amount collected
    struct BatchResult {
        uint32 processed;
        uint32 succeeded;
        uint32 failed;
        uint256 totalAmount;
    }

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a payment is successfully processed
    /// @param subscriptionId Subscription charged
    /// @param subscriber Subscriber address
    /// @param creator Creator receiving payment
    /// @param amount Payment amount
    /// @param token Payment token
    event PaymentProcessed(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        address indexed creator,
        uint256 amount,
        address token
    );

    /// @notice Emitted when a payment fails
    /// @param subscriptionId Subscription that failed
    /// @param subscriber Subscriber address
    /// @param reason Failure reason code
    event PaymentFailed(
        uint256 indexed subscriptionId,
        address indexed subscriber,
        bytes4 reason
    );

    /// @notice Emitted when a subscription enters grace period
    /// @param subscriptionId Subscription in grace
    /// @param deadline Grace period deadline
    event GracePeriodStarted(uint256 indexed subscriptionId, uint64 deadline);

    /// @notice Emitted when a subscription is cancelled due to non-payment
    /// @param subscriptionId Cancelled subscription
    event SubscriptionCancelledForNonPayment(uint256 indexed subscriptionId);

    /// @notice Emitted when protocol fee is updated
    /// @param oldFee Previous fee in basis points
    /// @param newFee New fee in basis points
    event ProtocolFeeUpdated(uint16 oldFee, uint16 newFee);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Thrown when payment is not yet due
    error PaymentNotDue();

    /// @notice Thrown when subscriber has insufficient balance
    error InsufficientBalance();

    /// @notice Thrown when subscriber has insufficient allowance
    error InsufficientAllowance();

    /// @notice Thrown when subscription is paused
    error SubscriptionPaused();

    /// @notice Thrown when subscription is cancelled
    error SubscriptionCancelled();

    /// @notice Thrown when subscription is in grace period
    error InGracePeriod();

    /// @notice Thrown when batch size exceeds maximum
    error BatchSizeExceeded();

    /// @notice Thrown when caller is not authorized processor
    error NotAuthorizedProcessor();

    /// @notice Thrown when fee exceeds maximum
    error FeeTooHigh();

    // =========================================================================
    // Functions
    // =========================================================================

    /// @notice Processes a single subscription payment
    /// @param subscriptionId Subscription to process
    /// @return success Whether payment succeeded
    function processPayment(uint256 subscriptionId) external returns (bool success);

    /// @notice Processes multiple subscription payments in batch
    /// @param subscriptionIds Array of subscriptions to process
    /// @return result Batch processing results
    function processBatch(
        uint256[] calldata subscriptionIds
    ) external returns (BatchResult memory result);

    /// @notice Checks if a subscription payment is due
    /// @param subscriptionId Subscription to check
    /// @return isDue Whether payment is due
    /// @return dueAmount Amount due
    function isPaymentDue(
        uint256 subscriptionId
    ) external view returns (bool isDue, uint256 dueAmount);

    /// @notice Gets the next payment due date for a subscription
    /// @param subscriptionId Subscription to check
    /// @return dueDate Unix timestamp of next payment
    function getNextPaymentDue(uint256 subscriptionId) external view returns (uint64 dueDate);

    /// @notice Gets payment history for a subscription
    /// @param subscriptionId Subscription to query
    /// @param limit Maximum records to return
    /// @return payments Array of payment executions
    function getPaymentHistory(
        uint256 subscriptionId,
        uint256 limit
    ) external view returns (PaymentExecution[] memory payments);

    /// @notice Returns current protocol fee in basis points
    /// @return feeBps Protocol fee (100 = 1%)
    function protocolFeeBps() external view returns (uint16 feeBps);

    /// @notice Updates protocol fee (admin only)
    /// @param newFeeBps New fee in basis points
    function setProtocolFee(uint16 newFeeBps) external;
}
