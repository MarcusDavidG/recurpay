// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "../base/RecurPayBase.sol";
import {ISubscriptionFactory} from "../interfaces/ISubscriptionFactory.sol";
import {RecurPayEvents} from "../libraries/RecurPayEvents.sol";
import {RecurPayErrors} from "../libraries/RecurPayErrors.sol";
import {BillingPeriod} from "../libraries/BillingPeriod.sol";

/// @title SubscriptionFactory
/// @author RecurPay Protocol
/// @notice Manages the creation and configuration of subscription plans
contract SubscriptionFactory is ISubscriptionFactory, RecurPayBase {
    // =========================================================================
    // State Variables
    // =========================================================================

    uint256 private _planCounter;
    mapping(uint256 => PlanConfig) private _plans;
    mapping(uint256 => PlanMetadata) private _planMetadata;
    mapping(address => uint256[]) private _creatorPlans;

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address initialOwner) RecurPayBase(initialOwner) {}

    // =========================================================================
    // External Functions - Plan Creation
    // =========================================================================

    /// @inheritdoc ISubscriptionFactory
    function createPlan(
        PlanConfig calldata config,
        PlanMetadata calldata metadata
    ) external nonReentrant whenNotPaused returns (uint256 planId) {
        // Input validation
        if (config.creator == address(0)) revert RecurPayErrors.ZeroAddress();
        if (config.price == 0) revert ISubscriptionFactory.InvalidPrice();
        if (!BillingPeriod.isValidBillingPeriod(config.billingPeriod)) {
            revert ISubscriptionFactory.InvalidBillingPeriod();
        }

        planId = ++_planCounter;

        _plans[planId] = PlanConfig({
            creator: config.creator,
            paymentToken: config.paymentToken,
            price: config.price,
            billingPeriod: config.billingPeriod,
            gracePeriod: config.gracePeriod,
            maxSubscribers: config.maxSubscribers,
            active: true // Plans are active by default
        });

        _planMetadata[planId] = metadata;
        _creatorPlans[config.creator].push(planId);

        emit ISubscriptionFactory.PlanCreated(
            planId,
            config.creator,
            config.paymentToken,
            config.price,
            config.billingPeriod
        );

        return planId;
    }

    // =========================================================================
    // External Functions - Plan Management
    // =========================================================================

    /// @inheritdoc ISubscriptionFactory
    function updatePlanPrice(uint256 planId, uint256 newPrice)
        external
        nonReentrant
        whenNotPaused
        _onlyPlanCreator(planId)
    {
        if (newPrice == 0) revert ISubscriptionFactory.InvalidPrice();

        _plans[planId].price = newPrice;

        emit ISubscriptionFactory.PlanUpdated(planId, newPrice, _plans[planId].active);
    }

    /// @inheritdoc ISubscriptionFactory
    function setPlanActive(uint256 planId, bool active)
        external
        nonReentrant
        whenNotPaused
        _onlyPlanCreator(planId)
    {
        PlanConfig storage plan = _plans[planId];
        if (plan.active == active) return; // No change

        plan.active = active;

        if (!active) {
            emit ISubscriptionFactory.PlanDeactivated(planId);
        }

        emit ISubscriptionFactory.PlanUpdated(planId, plan.price, active);
    }

    // =========================================================================
    // External Functions - View
    // =========================================================================

    /// @inheritdoc ISubscriptionFactory
    function getPlan(uint256 planId) external view returns (PlanConfig memory config) {
        if (_plans[planId].creator == address(0)) revert ISubscriptionFactory.PlanNotFound();
        return _plans[planId];
    }

    /// @inheritdoc ISubscriptionFactory
    function getPlanMetadata(uint256 planId) external view returns (PlanMetadata memory metadata) {
        return _planMetadata[planId];
    }

    /// @inheritdoc ISubscriptionFactory
    function getCreatorPlans(address creator) external view returns (uint256[] memory planIds) {
        return _creatorPlans[creator];
    }

    /// @inheritdoc ISubscriptionFactory
    function totalPlans() external view returns (uint256 count) {
        return _planCounter;
    }

    // =========================================================================
    // Internal Functions & Modifiers
    // =========================================================================

    /// @notice Ensures the caller is the creator of the specified plan
    modifier _onlyPlanCreator(uint256 planId) {
        if (_plans[planId].creator == address(0)) revert ISubscriptionFactory.PlanNotFound();
        if (_plans[planId].creator != msg.sender) revert ISubscriptionFactory.NotPlanCreator();
        _;
    }
