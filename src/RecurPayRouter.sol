// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {IPaymentProcessor} from "src/interfaces/IPaymentProcessor.sol";
import {ICreatorVault} from "src/interfaces/ICreatorVault.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecurPayRouter
/// @author RecurPay Protocol
/// @notice Unified entry point for RecurPay protocol interactions
contract RecurPayRouter is RecurPayBase {
    using SafeERC20 for IERC20;

    // ========================================================================
    // State Variables
    // ========================================================================

    ISubscriptionFactory public subscriptionFactory;
    ISubscriberRegistry public subscriberRegistry;
    IPaymentProcessor public paymentProcessor;
    ICreatorVault public creatorVault;

    // ========================================================================
    // Events
    // ========================================================================

    event ContractsUpdated(
        address indexed factory,
        address indexed registry,
        address indexed processor,
        address vault
    );

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(
        address factory,
        address registry,
        address processor,
        address vault,
        address initialOwner
    ) RecurPayBase(initialOwner) {
        if (factory == address(0)) revert RecurPayErrors.ZeroAddress();
        if (registry == address(0)) revert RecurPayErrors.ZeroAddress();
        if (processor == address(0)) revert RecurPayErrors.ZeroAddress();
        if (vault == address(0)) revert RecurPayErrors.ZeroAddress();

        subscriptionFactory = ISubscriptionFactory(factory);
        subscriberRegistry = ISubscriberRegistry(registry);
        paymentProcessor = IPaymentProcessor(processor);
        creatorVault = ICreatorVault(vault);
    }

    // ========================================================================
    // Admin Functions
    // ========================================================================

    /// @notice Updates protocol contract references
    function updateContracts(
        address factory,
        address registry,
        address processor,
        address vault
    ) external onlyOwner {
        if (factory != address(0)) subscriptionFactory = ISubscriptionFactory(factory);
        if (registry != address(0)) subscriberRegistry = ISubscriberRegistry(registry);
        if (processor != address(0)) paymentProcessor = IPaymentProcessor(processor);
        if (vault != address(0)) creatorVault = ICreatorVault(vault);

        emit ContractsUpdated(
            address(subscriptionFactory),
            address(subscriberRegistry),
            address(paymentProcessor),
            address(creatorVault)
        );
    }

    // ========================================================================
    // External Functions - Subscriber Actions
    // ========================================================================

    /// @notice Subscribe to a plan with initial payment
    /// @param planId Plan to subscribe to
    /// @return subscriptionId New subscription ID
    function subscribe(uint256 planId) external nonReentrant whenNotPaused returns (uint256 subscriptionId) {
        ISubscriptionFactory.PlanConfig memory plan = subscriptionFactory.getPlan(planId);

        if (plan.paymentToken != address(0)) {
            IERC20 token = IERC20(plan.paymentToken);
            if (token.allowance(msg.sender, address(paymentProcessor)) < plan.price) {
                revert RecurPayErrors.InsufficientAllowance();
            }
        }

        subscriptionId = subscriberRegistry.subscribe(planId, msg.sender);
        paymentProcessor.processPayment(subscriptionId);

        return subscriptionId;
    }

    // ========================================================================
    // External Functions - Subscription Management
    // ========================================================================

    /// @notice Pause a subscription
    function pauseSubscription(uint256 subscriptionId, uint32 duration) external nonReentrant {
        subscriberRegistry.pause(subscriptionId, duration);
    }

    /// @notice Resume a paused subscription
    function resumeSubscription(uint256 subscriptionId) external nonReentrant {
        subscriberRegistry.resume(subscriptionId);
    }

    /// @notice Cancel a subscription
    function cancelSubscription(uint256 subscriptionId) external nonReentrant {
        subscriberRegistry.cancel(subscriptionId);
    }

    /// @notice Get subscription details
    function getSubscription(uint256 subscriptionId) external view returns (ISubscriberRegistry.Subscription memory) {
        return subscriberRegistry.getSubscription(subscriptionId);
    }

    /// @notice Get all subscriptions for caller
    function getMySubscriptions() external view returns (uint256[] memory) {
        return subscriberRegistry.getSubscriberSubscriptions(msg.sender);
    }

    /// @notice Get active subscriptions for caller
    function getMyActiveSubscriptions() external view returns (uint256[] memory) {
        return subscriberRegistry.getActiveSubscriptions(msg.sender);
    }

    /// @notice Check if caller has active subscription to a plan
    function hasActiveSubscription(uint256 planId) external view returns (bool) {
        return subscriberRegistry.hasActiveSubscription(msg.sender, planId);
    }

    // ========================================================================
    // External Functions - Creator Actions
    // ========================================================================

    /// @notice Create a new subscription plan
    function createPlan(
        ISubscriptionFactory.PlanConfig calldata config,
        ISubscriptionFactory.PlanMetadata calldata metadata
    ) external nonReentrant whenNotPaused returns (uint256 planId) {
        return subscriptionFactory.createPlan(config, metadata);
    }

    /// @notice Update plan price
    function updatePlanPrice(uint256 planId, uint256 newPrice) external nonReentrant {
        subscriptionFactory.updatePlanPrice(planId, newPrice);
    }

    /// @notice Activate or deactivate a plan
    function setPlanActive(uint256 planId, bool active) external nonReentrant {
        subscriptionFactory.setPlanActive(planId, active);
    }

    /// @notice Withdraw creator revenue
    function withdrawRevenue(address token, uint256 amount) external nonReentrant {
        creatorVault.withdraw(token, amount);
    }

    /// @notice Withdraw all creator revenue for a token
    function withdrawAllRevenue(address token) external nonReentrant {
        creatorVault.withdrawAll(token);
    }

    /// @notice Set withdrawal address for revenue
    function setWithdrawalAddress(address recipient) external nonReentrant {
        creatorVault.setWithdrawalAddress(recipient);
    }

    /// @notice Configure auto-withdrawal
    function configureAutoWithdrawal(bool enabled, uint256 threshold) external nonReentrant {
        creatorVault.configureAutoWithdrawal(enabled, threshold);
    }

    /// @notice Get creator\'s plans
    function getCreatorPlans(address creator) external view returns (uint256[] memory) {
        return subscriptionFactory.getCreatorPlans(creator);
    }

    /// @notice Get creator\'s revenue stats
    function getCreatorRevenue(address creator) external view returns (ICreatorVault.RevenueStats memory) {
        return creatorVault.getRevenueStats(creator);
    }

    /// @notice Get creator\'s token balance
    function getCreatorBalance(address creator, address token) external view returns (uint256) {
        return creatorVault.getBalance(creator, token);
    }

    // ========================================================================
    // External Functions - Protocol Queries
    // ========================================================================

    /// @notice Get plan details
    function getPlan(uint256 planId) external view returns (ISubscriptionFactory.PlanConfig memory) {
        return subscriptionFactory.getPlan(planId);
    }

    /// @notice Get plan metadata
    function getPlanMetadata(uint256 planId) external view returns (ISubscriptionFactory.PlanMetadata memory) {
        return subscriptionFactory.getPlanMetadata(planId);
    }

    /// @notice Get plan subscriber count
    function getPlanSubscriberCount(uint256 planId) external view returns (uint256) {
        return subscriberRegistry.getPlanSubscriberCount(planId);
    }

    /// @notice Check if payment is due for a subscription
    function isPaymentDue(uint256 subscriptionId) external view returns (bool isDue, uint256 amount) {
        return paymentProcessor.isPaymentDue(subscriptionId);
    }

    /// @notice Get next payment due date
    function getNextPaymentDue(uint256 subscriptionId) external view returns (uint64) {
        return paymentProcessor.getNextPaymentDue(subscriptionId);
    }

    /// @notice Get protocol fee
    function getProtocolFee() external view returns (uint16) {
        return paymentProcessor.protocolFeeBps();
    }

    /// @notice Get total plans count
    function totalPlans() external view returns (uint256) {
        return subscriptionFactory.totalPlans();
    }

    /// @notice Get total subscriptions count
    function totalSubscriptions() external view returns (uint256) {
        return subscriberRegistry.totalSubscriptions();
    }

    /// @notice Allows contract to receive ETH
    receive() external payable {}
}
