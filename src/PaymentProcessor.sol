// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {BillingPeriod} from "src/libraries/BillingPeriod.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PaymentProcessor
/// @author RecurPay Protocol
/// @notice Processes recurring subscription payments
contract PaymentProcessor is IPaymentProcessor, RecurPayBase {
    using SafeERC20 for IERC20;

    // ========================================================================
    // Constants
    // ========================================================================

    /// @notice Maximum protocol fee (10%)
    uint16 public constant MAX_FEE_BPS = 1000;

    /// @notice Maximum batch size for processing
    uint32 public constant MAX_BATCH_SIZE = 100;

    // ========================================================================
    // State Variables
    // ========================================================================

    /// @notice Reference to SubscriptionFactory
    ISubscriptionFactory public subscriptionFactory;

    /// @notice Reference to SubscriberRegistry
    ISubscriberRegistry public subscriberRegistry;

    /// @notice Reference to CreatorVault
    ICreatorVault public creatorVault;

    /// @notice Protocol fee in basis points
    uint16 private _protocolFeeBps;

    /// @notice Treasury address for protocol fees
    address public treasury;

    /// @notice Subscription ID => payment history
    mapping(uint256 => PaymentExecution[]) private _paymentHistory;

    /// @notice Accumulated protocol fees per token
    mapping(address => uint256) private _protocolFees;

    // ========================================================================
    // Events
    // ========================================================================

    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event ProtocolFeesWithdrawn(address indexed token, uint256 amount);

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(
        address factory,
        address registry,
        address vault,
        address treasuryAddress,
        uint16 feeBps,
        address initialOwner
    ) RecurPayBase(initialOwner) {
        if (factory == address(0)) revert RecurPayErrors.ZeroAddress();
        if (registry == address(0)) revert RecurPayErrors.ZeroAddress();
        if (vault == address(0)) revert RecurPayErrors.ZeroAddress();
        if (treasuryAddress == address(0)) revert RecurPayErrors.ZeroAddress();
        if (feeBps > MAX_FEE_BPS) revert IPaymentProcessor.FeeTooHigh();

        subscriptionFactory = ISubscriptionFactory(factory);
        subscriberRegistry = ISubscriberRegistry(registry);
        creatorVault = ICreatorVault(vault);
        treasury = treasuryAddress;
        _protocolFeeBps = feeBps;
    }

    // ========================================================================
    // Admin Functions
    // ========================================================================

    /// @inheritdoc IPaymentProcessor
    function setProtocolFee(uint16 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) revert IPaymentProcessor.FeeTooHigh();

        uint16 oldFee = _protocolFeeBps;
        _protocolFeeBps = newFeeBps;

        emit ProtocolFeeUpdated(oldFee, newFeeBps);
    }

    /// @notice Updates the treasury address
    /// @param newTreasury New treasury address
    function setTreasury(address newTreasury) external onlyOwner {
        if (newTreasury == address(0)) revert RecurPayErrors.ZeroAddress();

        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryUpdated(oldTreasury, newTreasury);
    }

    /// @inheritdoc IPaymentProcessor
    function protocolFeeBps() external view returns (uint16 feeBps) {
        return _protocolFeeBps;
    }

    /// @notice Withdraws accumulated protocol fees
    /// @param token Token to withdraw (address(0) for ETH)
    function withdrawProtocolFees(address token) external onlyOwner nonReentrant {
        uint256 amount = _protocolFees[token];
        if (amount == 0) revert RecurPayErrors.ZeroAmount();

        _protocolFees[token] = 0;

        if (token == address(0)) {
            (bool success, ) = treasury.call{value: amount}("");
            if (!success) revert RecurPayErrors.ETHTransferFailed();
        } else {
            IERC20(token).safeTransfer(treasury, amount);
        }

        emit ProtocolFeesWithdrawn(token, amount);
    }

    /// @notice Gets accumulated protocol fees for a token
    /// @param token Token address
    /// @return amount Accumulated fees
    function getAccumulatedFees(address token) external view returns (uint256 amount) {
        return _protocolFees[token];
    }

    // ========================================================================
    // External Functions - Payment Processing
    // ========================================================================

    /// @inheritdoc IPaymentProcessor
    function processPayment(uint256 subscriptionId) external nonReentrant whenNotPaused returns (bool success) {
        return _processPayment(subscriptionId);
    }

    /// @notice Internal payment processing logic
    function _processPayment(uint256 subscriptionId) internal returns (bool success) {
        // Get subscription data
        ISubscriberRegistry.Subscription memory sub = subscriberRegistry.getSubscription(subscriptionId);

        // Check subscription status
        if (sub.status == ISubscriberRegistry.SubscriptionStatus.Cancelled) {
            revert IPaymentProcessor.SubscriptionCancelled();
        }
        if (sub.status == ISubscriberRegistry.SubscriptionStatus.Paused) {
            revert IPaymentProcessor.SubscriptionPaused();
        }

        // Get plan data
        ISubscriptionFactory.PlanConfig memory plan = subscriptionFactory.getPlan(sub.planId);

        // Check if payment is due
        if (block.timestamp < sub.currentPeriodEnd) {
            revert IPaymentProcessor.PaymentNotDue();
        }

        address subscriber = sub.subscriber;
        address token = plan.paymentToken;
        uint256 amount = plan.price;

        // Calculate fees
        uint256 protocolFee = PercentageMath.calculatePercentage(amount, _protocolFeeBps);
        uint256 creatorAmount = amount - protocolFee;

        // Process ERC20 payment
        if (token != address(0)) {
            IERC20 paymentToken = IERC20(token);

            // Check balance and allowance
            if (paymentToken.balanceOf(subscriber) < amount) {
                _handlePaymentFailure(subscriptionId, sub, plan, IPaymentProcessor.InsufficientBalance.selector);
                return false;
            }
            if (paymentToken.allowance(subscriber, address(this)) < amount) {
                _handlePaymentFailure(subscriptionId, sub, plan, IPaymentProcessor.InsufficientAllowance.selector);
                return false;
            }

            // Transfer to this contract first
            paymentToken.safeTransferFrom(subscriber, address(this), amount);

            // Send to creator vault
            paymentToken.safeTransfer(address(creatorVault), creatorAmount);
        }

        // Deposit to creator vault
        creatorVault.deposit(plan.creator, token, creatorAmount, subscriptionId);

        // Accumulate protocol fee
        if (protocolFee > 0) {
            _protocolFees[token] += protocolFee;
        }

        // Record payment in registry
        subscriberRegistry.recordPayment(subscriptionId, amount);

        // Record in history
        _paymentHistory[subscriptionId].push(PaymentExecution({
            subscriptionId: subscriptionId,
            amount: amount,
            token: token,
            timestamp: uint64(block.timestamp),
            success: true
        }));

        emit PaymentProcessed(subscriptionId, subscriber, plan.creator, amount, token);

        return true;
    }

    // ========================================================================
    // External Functions - Batch Processing
    // ========================================================================

    /// @inheritdoc IPaymentProcessor
    function processBatch(
        uint256[] calldata subscriptionIds
    ) external nonReentrant whenNotPaused returns (BatchResult memory result) {
        uint256 length = subscriptionIds.length;
        if (length > MAX_BATCH_SIZE) revert IPaymentProcessor.BatchSizeExceeded();

        result.processed = uint32(length);

        for (uint256 i = 0; i < length; i++) {
            try this.processPaymentInternal(subscriptionIds[i]) returns (bool success, uint256 amount) {
                if (success) {
                    result.succeeded++;
                    result.totalAmount += amount;
                } else {
                    result.failed++;
                }
            } catch {
                result.failed++;
            }
        }

        return result;
    }

    /// @notice Internal function for batch processing (allows try/catch)
    /// @param subscriptionId Subscription to process
    /// @return success Whether payment succeeded
    /// @return amount Amount collected
    function processPaymentInternal(uint256 subscriptionId) external returns (bool success, uint256 amount) {
        require(msg.sender == address(this), "Internal only");

        ISubscriberRegistry.Subscription memory sub = subscriberRegistry.getSubscription(subscriptionId);
        ISubscriptionFactory.PlanConfig memory plan = subscriptionFactory.getPlan(sub.planId);

        success = _processPayment(subscriptionId);
        amount = success ? plan.price : 0;

        return (success, amount);
    }

    // ========================================================================
    // Internal Functions - Grace Period
    // ========================================================================

    /// @notice Handles payment failure with grace period logic
    function _handlePaymentFailure(
        uint256 subscriptionId,
        ISubscriberRegistry.Subscription memory sub,
        ISubscriptionFactory.PlanConfig memory plan,
        bytes4 reason
    ) internal {
        // Record failed payment
        _paymentHistory[subscriptionId].push(PaymentExecution({
            subscriptionId: subscriptionId,
            amount: plan.price,
            token: plan.paymentToken,
            timestamp: uint64(block.timestamp),
            success: false
        }));

        emit PaymentFailed(subscriptionId, sub.subscriber, reason);

        // Check if already in grace period
        if (sub.status == ISubscriberRegistry.SubscriptionStatus.GracePeriod) {
            // Check if grace period expired
            uint64 graceDeadline = sub.currentPeriodEnd + plan.gracePeriod;
            if (block.timestamp > graceDeadline) {
                // Cancel subscription
                subscriberRegistry.updateStatus(subscriptionId, ISubscriberRegistry.SubscriptionStatus.Cancelled);
                emit SubscriptionCancelledForNonPayment(subscriptionId);
            }
        } else if (sub.status == ISubscriberRegistry.SubscriptionStatus.Active) {
            // Enter grace period
            subscriberRegistry.updateStatus(subscriptionId, ISubscriberRegistry.SubscriptionStatus.GracePeriod);
            uint64 graceDeadline = sub.currentPeriodEnd + plan.gracePeriod;
            emit GracePeriodStarted(subscriptionId, graceDeadline);
        }
    }

    /// @inheritdoc IPaymentProcessor
    function isPaymentDue(
        uint256 subscriptionId
    ) external view returns (bool) {
        ISubscriberRegistry.Subscription memory sub = subscriberRegistry.getSubscription(subscriptionId);
        return block.timestamp >= sub.currentPeriodEnd;
    }

    /// @inheritdoc IPaymentProcessor
    function getNextPaymentDue(uint256 subscriptionId) external view returns (uint64 dueDate) {
        ISubscriberRegistry.Subscription memory sub = subscriberRegistry.getSubscription(subscriptionId);
        return sub.currentPeriodEnd;
    }

    /// @inheritdoc IPaymentProcessor
    function getPaymentHistory(
        uint256 subscriptionId,
        uint256 cursor,
        uint256 size
    ) external view returns (PaymentExecution[] memory executions, uint256 nextCursor) {
        uint256 historyLength = _paymentHistory[subscriptionId].length;
        uint256 start = cursor;
        if (start >= historyLength) {
            return (new PaymentExecution[](0), historyLength);
        }
        uint256 end = start + size;
        if (end > historyLength) {
            end = historyLength;
        }
        executions = new PaymentExecution[](end - start);
        for (uint256 i = start; i < end; i++) {
            executions[i - start] = _paymentHistory[subscriptionId][i];
        }
        nextCursor = end;
        return (executions, nextCursor);
    }
}
