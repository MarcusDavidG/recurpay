// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title RecurPayErrors
/// @author RecurPay Protocol
/// @notice Shared error definitions for the RecurPay protocol
library RecurPayErrors {
    // =========================================================================
    // Access Control Errors
    // =========================================================================

    /// @notice Thrown when caller lacks required permissions
    error Unauthorized();

    /// @notice Thrown when caller is not the contract owner
    error NotOwner();

    /// @notice Thrown when caller is not the designated admin
    error NotAdmin();

    /// @notice Thrown when caller is not a trusted processor
    error NotProcessor();

    /// @notice Thrown when contract is paused
    error ContractPaused();

    /// @notice Thrown when contract is not paused (for unpause operations)
    error ContractNotPaused();

    // =========================================================================
    // Validation Errors
    // =========================================================================

    /// @notice Thrown when address parameter is zero
    error ZeroAddress();

    /// @notice Thrown when amount parameter is zero
    error ZeroAmount();

    /// @notice Thrown when array parameter is empty
    error EmptyArray();

    /// @notice Thrown when array lengths don't match
    error ArrayLengthMismatch();

    /// @notice Thrown when value is out of acceptable range
    error OutOfRange();

    /// @notice Thrown when deadline has passed
    error DeadlineExpired();

    /// @notice Thrown when signature is invalid
    error InvalidSignature();

    /// @notice Thrown when nonce has already been used
    error NonceAlreadyUsed();

    // =========================================================================
    // Token Errors
    // =========================================================================

    /// @notice Thrown when token is not supported by the protocol
    error TokenNotSupported();

    /// @notice Thrown when token transfer fails
    error TokenTransferFailed();

    /// @notice Thrown when ETH transfer fails
    error ETHTransferFailed();

    /// @notice Thrown when insufficient token balance
    error InsufficientBalance();

    /// @notice Thrown when insufficient token allowance
    error InsufficientAllowance();

    // =========================================================================
    // Plan Errors
    // =========================================================================

    /// @notice Thrown when plan does not exist
    error PlanDoesNotExist();

    /// @notice Thrown when plan is not active
    error PlanInactive();

    /// @notice Thrown when plan has reached maximum capacity
    error PlanCapacityReached();

    /// @notice Thrown when plan configuration is invalid
    error InvalidPlanConfig();

    /// @notice Thrown when billing period is invalid
    error InvalidBillingPeriod();

    /// @notice Thrown when price is invalid
    error InvalidPrice();

    // =========================================================================
    // Subscription Errors
    // =========================================================================

    /// @notice Thrown when subscription does not exist
    error SubscriptionDoesNotExist();

    /// @notice Thrown when subscription is not active
    error SubscriptionInactive();

    /// @notice Thrown when subscription is already cancelled
    error SubscriptionAlreadyCancelled();

    /// @notice Thrown when subscription is already paused
    error SubscriptionAlreadyPaused();

    /// @notice Thrown when user already has subscription to plan
    error DuplicateSubscription();

    /// @notice Thrown when subscription cannot be renewed
    error CannotRenew();

    // =========================================================================
    // Payment Errors
    // =========================================================================

    /// @notice Thrown when payment is not yet due
    error PaymentNotYetDue();

    /// @notice Thrown when payment has already been processed for period
    error PaymentAlreadyProcessed();

    /// @notice Thrown when payment processing fails
    error PaymentFailed();

    /// @notice Thrown when refund fails
    error RefundFailed();

    /// @notice Thrown when fee calculation overflows
    error FeeOverflow();

    // =========================================================================
    // Vault Errors
    // =========================================================================

    /// @notice Thrown when vault does not exist
    error VaultDoesNotExist();

    /// @notice Thrown when vault already exists for creator
    error VaultAlreadyExists();

    /// @notice Thrown when vault balance is insufficient
    error InsufficientVaultBalance();

    /// @notice Thrown when withdrawal is not allowed
    error WithdrawalNotAllowed();

    // =========================================================================
    // Reentrancy Errors
    // =========================================================================

    /// @notice Thrown when reentrancy is detected
    error ReentrancyGuard();
}
