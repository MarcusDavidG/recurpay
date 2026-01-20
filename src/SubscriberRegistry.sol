// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {ISubscriberRegistry} from "src/interfaces/ISubscriberRegistry.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {RecurPayEvents} from "src/libraries/RecurPayEvents.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";

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
    mapping(address => SubscriberProfile) private _subscriberProfiles;
    
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

    /// @notice Subscribes a user to a subscription plan.
    /// @param planId The ID of the plan to subscribe to.
    /// @param subscriber The address of the user subscribing.
    /// @return subscriptionId The ID of the newly created subscription.
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

        // Update subscriber profile
        SubscriberProfile storage profile = _subscriberProfiles[subscriber];
        if (profile.firstSubscriptionDate == 0) {
            profile.firstSubscriptionDate = startTime;
        }
        profile.subscriptionCount++;
        profile.activeSubscriptions++;

        emit ISubscriberRegistry.SubscriptionCreated(
            subscriptionId,
            planId,
            subscriber,
            plan.creator
        );

        return subscriptionId;
    }
    
    /// @notice Pauses a subscription.
    /// @param subscriptionId The ID of the subscription to pause.
    /// @param pauseDuration The duration to pause the subscription for. If 0, the subscription is paused indefinitely.
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

        _subscriberProfiles[sub.subscriber].activeSubscriptions--;

        emit ISubscriberRegistry.SubscriptionPaused(subscriptionId, pausedUntil);
    }

    /// @notice Resumes a paused subscription.
    /// @param subscriptionId The ID of the subscription to resume.
    function resume(uint256 subscriptionId)
        external
        nonReentrant
        _onlySubscriber(subscriptionId)
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.status != SubscriptionStatus.Paused) revert ISubscriberRegistry.NotPaused();

        sub.status = SubscriptionStatus.Active;
        sub.pausedUntil = 0;

        _subscriberProfiles[sub.subscriber].activeSubscriptions++;

        emit ISubscriberRegistry.SubscriptionResumed(subscriptionId);
    }

    /// @notice Cancels a subscription.
    /// @param subscriptionId The ID of the subscription to cancel.
    function cancel(uint256 subscriptionId)
        external
        nonReentrant
        _onlySubscriber(subscriptionId)
    {
        Subscription storage sub = _subscriptions[subscriptionId];
        if (sub.status == SubscriptionStatus.Cancelled) revert ISubscriberRegistry.AlreadyCancelled();

        // Only decrement activeSubscriptions if it was active
        if(sub.status == SubscriptionStatus.Active) {
            _subscriberProfiles[sub.subscriber].activeSubscriptions--;
        }
        sub.status = SubscriptionStatus.Cancelled;

        emit ISubscriberRegistry.SubscriptionCancelled(subscriptionId, "USER", 0);
    }
    
    /// @notice Updates the status of a subscription. Can only be called by the payment processor.
    /// @param subscriptionId The ID of the subscription to update.
    /// @param newStatus The new status of the subscription.
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

        if (oldStatus == SubscriptionStatus.Active && (newStatus == SubscriptionStatus.Paused || newStatus == SubscriptionStatus.Cancelled)) {
            _subscriberProfiles[sub.subscriber].activeSubscriptions--;
        } else if (oldStatus == SubscriptionStatus.Paused && newStatus == SubscriptionStatus.Active) {
            _subscriberProfiles[sub.subscriber].activeSubscriptions++;
        }

        sub.status = newStatus;
        emit ISubscriberRegistry.SubscriptionStatusChanged(subscriptionId, oldStatus, newStatus);
    }

    /// @notice Records a payment for a subscription. Can only be called by the payment processor.
    /// @param subscriptionId The ID of the subscription to record a payment for.
    /// @param amount The amount of the payment.
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

        _subscriberProfiles[sub.subscriber].totalSpent += amount;

        emit ISubscriberRegistry.SubscriptionRenewed(subscriptionId, sub.currentPeriodEnd);
    }

    // =========================================================================
    // External Functions - Configuration
    // =========================================================================

    /// @notice Sets the authorized payment processor address.
    /// @param newProcessor The address of the new payment processor.
    function setProcessor(address newProcessor) external onlyOwner {
        if (newProcessor == address(0)) revert RecurPayErrors.ZeroAddress();
        processor = newProcessor;
        emit ProcessorSet(newProcessor);
    }

    // =========================================================================
    // External Functions - View
    // =========================================================================

    /// @notice Gets the details of a subscription.
    /// @param subscriptionId The ID of the subscription to retrieve.
    /// @return subscription The details of the subscription.
    function getSubscription(
        uint256 subscriptionId
    ) external view returns (Subscription memory subscription) {
        if (_subscriptions[subscriptionId].id == 0) revert ISubscriberRegistry.SubscriptionNotFound();
        return _subscriptions[subscriptionId];
    }

    /// @notice Gets the IDs of all subscriptions for a specific subscriber.
    /// @param subscriber The address of the subscriber.
    /// @return subscriptionIds An array of subscription IDs.
    function getSubscriberSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds) {
        return _subscriberSubscriptions[subscriber];
    }

    /// @notice Gets the IDs of all active subscriptions for a specific subscriber.
    /// @param subscriber The address of the subscriber.
    /// @return subscriptionIds An array of active subscription IDs.
    function getActiveSubscriptions(
        address subscriber
    ) external view returns (uint256[] memory subscriptionIds) {
        uint256[] memory allSubscriptions = _subscriberSubscriptions[subscriber];
        uint256 activeCount = 0;
        for (uint i = 0; i < allSubscriptions.length; i++) {
            if (_subscriptions[allSubscriptions[i]].status == SubscriptionStatus.Active) {
                activeCount++;
            }
        }

        if (activeCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory activeSubscriptions = new uint256[](activeCount);
        uint256 index = 0;
        for (uint i = 0; i < allSubscriptions.length; i++) {
            if (_subscriptions[allSubscriptions[i]].status == SubscriptionStatus.Active) {
                activeSubscriptions[index++] = allSubscriptions[i];
            }
        }
        return activeSubscriptions;
    }

    /// @notice Gets the profile of a subscriber.
    /// @param subscriber The address of the subscriber.
    /// @return profile The profile of the subscriber.
    function getSubscriberProfile(
        address subscriber
    ) external view returns (SubscriberProfile memory profile) {
        return _subscriberProfiles[subscriber];
    }

    /// @notice Gets the addresses of all subscribers to a specific plan.
    /// @param planId The ID of the plan.
    /// @return subscribers An array of subscriber addresses.
    function getPlanSubscribers(
        uint256 planId
    ) external view returns (address[] memory subscribers) {
        return _planSubscribers[planId];
    }

    /// @notice Gets the number of subscribers to a specific plan.
    /// @param planId The ID of the plan.
    /// @return count The number of subscribers.
    function getPlanSubscriberCount(uint256 planId) external view returns (uint256 count) {
        return _planSubscribers[planId].length;
    }

    /// @notice Checks if a subscriber has an active subscription to a specific plan.
    /// @param subscriber The address of the subscriber.
    /// @param planId The ID of the plan.
    /// @return isActive True if the subscriber has an active subscription, false otherwise.
    function hasActiveSubscription(
        address subscriber,
        uint256 planId
    ) external view returns (bool isActive) {
        uint256 subscriptionId = _subscriptionIds[subscriber][planId];
        if (subscriptionId == 0) return false;
        return _subscriptions[subscriptionId].status == SubscriptionStatus.Active;
    }

    /// @notice Gets the total number of subscriptions created.
    /// @return count The total number of subscriptions.
    function totalSubscriptions() external view returns (uint256 count) {
        return _subscriptionCounter;
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

