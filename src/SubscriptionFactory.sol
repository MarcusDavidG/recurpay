// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RecurPayBase} from "src/base/RecurPayBase.sol";
import {ISubscriptionFactory} from "src/interfaces/ISubscriptionFactory.sol";
import {RecurPayEvents} from "src/libraries/RecurPayEvents.sol";
import {RecurPayErrors} from "src/libraries/RecurPayErrors.sol";
import {BillingPeriod} from "src/libraries/BillingPeriod.sol";

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
    mapping(address => bool) public supportedTokens;

    /// @notice Emitted when a token's support status is changed
    event SupportedTokenSet(address indexed token, bool isSupported);

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor(address initialOwner) RecurPayBase(initialOwner) {
        // ETH is always supported
        supportedTokens[address(0)] = true;
    }

    // =========================================================================
    // External Functions - Plan Creation
    // =========================================================================

    /// @notice Creates a new subscription plan.
    /// @param config The configuration for the new plan.
    /// @param metadata The metadata for the new plan.
    /// @return planId The ID of the newly created plan.
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
        if (!supportedTokens[config.paymentToken]) {
            revert ISubscriptionFactory.UnsupportedPaymentToken();
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

    /// @notice Updates the price of a subscription plan.
    /// @param planId The ID of the plan to update.
    /// @param newPrice The new price for the plan.
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

    /// @notice Sets a subscription plan as active or inactive.
    /// @param planId The ID of the plan to update.
    /// @param active The new active status for the plan.
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
    // External Functions - Token Management
    // =========================================================================

    /// @notice Sets a token as supported or unsupported for payments
    /// @param token The address of the ERC20 token
    /// @param isSupported The new support status
    function setSupportedToken(address token, bool isSupported) external onlyOwner {
        if (token == address(0)) revert("ETH support cannot be changed");
        supportedTokens[token] = isSupported;
        emit SupportedTokenSet(token, isSupported);
    }

    // =========================================================================
    // External Functions - View
    // =========================================================================

    /// @notice Gets the configuration of a subscription plan.
    /// @param planId The ID of the plan to retrieve.
    /// @return config The configuration of the plan.
    function getPlan(uint256 planId) external view returns (PlanConfig memory config) {
        if (_plans[planId].creator == address(0)) revert ISubscriptionFactory.PlanNotFound();
        return _plans[planId];
    }
    
    /// @notice Gets the metadata of a subscription plan.
    /// @param planId The ID of the plan to retrieve.
    /// @return metadata The metadata of the plan.
    function getPlanMetadata(uint256 planId) external view returns (PlanMetadata memory metadata) {
        return _planMetadata[planId];
    }

    /// @notice Gets the IDs of all plans created by a specific creator.
    /// @param creator The address of the creator.
    /// @return planIds An array of plan IDs.
    function getCreatorPlans(address creator) external view returns (uint256[] memory planIds) {
        return _creatorPlans[creator];
    }

    /// @notice Gets the total number of subscription plans created.
    /// @return count The total number of plans.
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
}
