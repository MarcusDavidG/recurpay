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
    uint256 private _subscriptionCounter;

    mapping(uint256 => Subscription) private _subscriptions;
    mapping(address => uint256[]) private _subscriberSubscriptions;
    mapping(uint256 => address[]) private _planSubscribers;
    mapping(address => mapping(uint256 => uint256)) private _subscriptionIds;

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
    
    function pause(uint256 subscriptionId, uint32 pauseDuration) external pure {
        revert("Not Implemented");
    }

    function resume(uint256 subscriptionId) external pure {
        revert("Not Implemented");
    }

    function cancel(uint256 subscriptionId) external pure {
        revert("Not Implemented");
    }
    
    function updateStatus(uint256 subscriptionId, SubscriptionStatus newStatus) external pure {
        revert("Not Implemented");
    }

    function recordPayment(uint256 subscriptionId, uint256 amount) external pure {
        revert("Not Implemented");
    }

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
}
