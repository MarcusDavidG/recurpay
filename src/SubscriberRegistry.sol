// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "../base/RecurPayBase.sol";
import {ISubscriberRegistry} from "../interfaces/ISubscriberRegistry.sol";
import {ISubscriptionFactory} from "../interfaces/ISubscriptionFactory.sol";
import {RecurPayEvents} from "../libraries/RecurPayEvents.sol";
import {RecurPayErrors} from "../libraries/RecurPayErrors.sol";

/// @title SubscriberRegistry
/// @author RecurPay Protocol
/// @notice Manages subscription state and subscriber data
contract SubscriberRegistry is ISubscriberRegistry, RecurPayBase {
    // =========================================================================
    // State Variables
    // =========================================================================

    ISubscriptionFactory public subscriptionFactory;
    address public processor;
    uint256 private _subscriptionCounter;

    mapping(uint256 => Subscription) private _subscriptions;
    mapping(address => uint256[]) private _subscriberSubscriptions;
    mapping(uint256 => address[]) private _planSubscribers;
    mapping(address => mapping(uint256 => uint256)) private _subscriptionIds;
    
    // =========================================================================
    // Events
    // =========================================================================

    event ProcessorSet(address indexed newProcessor);

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address factoryAddress, address initialOwner) RecurPayBase(initialOwner) {
        if (factoryAddress == address(0)) revert RecurPayErrors.ZeroAddress();
        subscriptionFactory = ISubscriptionFactory(factoryAddress);
    }

    // =========================================================================
    // External Functions - Subscription Management
    // =========================================================================

    /// @inheritdoc ISubscriberRegistry
    function subscribe(
        uint256 planId,
        address subscriber
    ) external nonReentrant whenNotPaused returns (uint256 subscriptionId) {
        if (subscriber == address(0)) revert RecurPayErrors.ZeroAddress();
        if (_subscriptionIds[subscriber][planId] != 0) revert ISubscriberRegistry.AlreadySubscribed();

        ISubscriptionFactory.PlanConfig memory plan = subscriptionFactory.getPlan(planId);
        if (plan.creator == address(0)) revert ISubscriptionFactory.PlanNotFound();
        if (!plan.active) revert ISubscriptionFactory.PlanNotActive();
        if (plan.maxSubscribers > 0 && _planSubscribers[planId].length >= plan.maxSubscribers) {
            revert ISubscriberRegistry.PlanAtCapacity();
        }

        subscriptionId = ++_subscriptionCounter;
        _subscriptionIds[subscriber][planId] = subscriptionId;

        uint64 startTime = uint64(block.timestamp);

        _subscriptions[subscriptionId] = Subscription({
            id: subscriptionId,
            planId: planId,
            subscriber: subscriber,
            status: SubscriptionStatus.Active,
            startDate: startTime,
            currentPeriodStart: startTime,
            currentPeriodEnd: startTime + plan.billingPeriod,
            lastPaymentDate: startTime,
            pausedUntil: 0,
            totalPaid: 0 // Initial payment is handled by the processor
        });

        _subscriberSubscriptions[subscriber].push(subscriptionId);
        _planSubscribers[planId].push(subscriber);

        emit ISubscriberRegistry.SubscriptionCreated(
            subscriptionId,
            planId,
            subscriber,
            plan.creator
        );

        return subscriptionId;
    }
    
    /// @inheritdoc ISubscriberRegistry
    function pause(uint256 subscriptionId, uint32 pauseDuration)
        external
        nonReentrant
        _onlySubscriber(subscriptionId)
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.status != SubscriptionStatus.Active) revert ISubscriberRegistry.SubscriptionNotActive();

        sub.status = SubscriptionStatus.Paused;
        uint64 pausedUntil = (pauseDuration == 0) ? type(uint64).max : uint64(block.timestamp) + pauseDuration;
        sub.pausedUntil = pausedUntil;

        emit ISubscriberRegistry.SubscriptionPaused(subscriptionId, pausedUntil);
    }

    /// @inheritdoc ISubscriberRegistry
    function resume(uint256 subscriptionId)
        external
        nonReentrant
        _onlySubscriber(subscriptionId)
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.status != SubscriptionStatus.Paused) revert ISubscriberRegistry.NotPaused();

        sub.status = SubscriptionStatus.Active;
        sub.pausedUntil = 0;

        emit ISubscriberRegistry.SubscriptionResumed(subscriptionId);
    }

    function cancel(uint256 subscriptionId) external pure {
        revert("Not Implemented");
    }
    
    /// @inheritdoc ISubscriberRegistry
    function updateStatus(uint256 subscriptionId, SubscriptionStatus newStatus)
        external
        nonReentrant
        whenNotPaused
        _onlyProcessor
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.id == 0) revert ISubscriberRegistry.SubscriptionNotFound();

        SubscriptionStatus oldStatus = sub.status;
        if (oldStatus == newStatus) return;

        sub.status = newStatus;
        emit ISubscriberRegistry.SubscriptionStatusChanged(subscriptionId, oldStatus, newStatus);
    }

    /// @inheritdoc ISubscriberRegistry
    function recordPayment(uint256 subscriptionId, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        _onlyProcessor
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.id == 0) revert ISubscriberRegistry.SubscriptionNotFound();

        ISubscriptionFactory.PlanConfig memory plan = subscriptionFactory.getPlan(sub.planId);

        sub.lastPaymentDate = uint64(block.timestamp);
        sub.totalPaid += amount;
        sub.currentPeriodStart = sub.currentPeriodEnd;
        sub.currentPeriodEnd += plan.billingPeriod;

        emit ISubscriberRegistry.SubscriptionRenewed(subscriptionId, sub.currentPeriodEnd);
    }

    // =========================================================================
    // External Functions - Configuration
    // =========================================================================

    /// @notice Sets the authorized payment processor address
    function setProcessor(address newProcessor) external onlyOwner {
        if (newProcessor == address(0)) revert RecurPayErrors.ZeroAddress();
        processor = newProcessor;
        emit ProcessorSet(newProcessor);
    }

    // =========================================================================
    // External Functions - View (To be implemented)
    // =========================================================================

    function getSubscription(
        uint256 subscriptionId
    ) external view returns (Subscription memory subscription) {
        revert("Not Implemented");
    }

    function getSubscriberSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds) {
        revert("Not Implemented");
    }

    function getActiveSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds) {
        revert("Not Implemented");
    }

    function getSubscriberProfile(
        address subscriber
    ) external view returns (SubscriberProfile memory profile) {
        revert("Not Implemented");
    }

    function getPlanSubscribers(
        uint256 planId
    ) external view returns (address[] memory subscribers) {
        revert("Not Implemented");
    }

    function getPlanSubscriberCount(uint256 planId) external view returns (uint256 count) {
        revert("Not Implemented");
    }

    function hasActiveSubscription(
        address subscriber,
        uint256 planId
    ) external view returns (bool isActive) {
        revert("Not Implemented");
    }

    function totalSubscriptions() external view returns (uint256 count) {
        revert("Not Implemented");
    }
    
    // =========================================================================
    // Modifiers
    // =========================================================================

    /// @notice Ensures the caller is the authorized payment processor
    modifier _onlyProcessor() {
        if (msg.sender != processor) revert RecurPayErrors.NotProcessor();
        _;
    }

    /// @notice Ensures the caller is the subscriber of the specified subscription
    modifier _onlySubscriber(uint256 subscriptionId) {
        if (_subscriptions[subscriptionId].id == 0) revert ISubscriberRegistry.SubscriptionNotFound();
        if (_subscriptions[subscriptionId].subscriber != msg.sender) revert ISubscriberRegistry.NotSubscriber();
        _;
    }
}

