// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ISubscriptionFactory
/// @author RecurPay Protocol
/// @notice Interface for creating and managing subscription plans on Base
interface ISubscriptionFactory {
    // =========================================================================
    // Structs
    // =========================================================================

    /// @notice Configuration for a subscription plan
    /// @param creator Address of the plan creator
    /// @param paymentToken Token used for payments (address(0) for ETH)
    /// @param price Price per billing period
    /// @param billingPeriod Duration of each billing period in seconds
    /// @param gracePeriod Grace period after billing date in seconds
    /// @param maxSubscribers Maximum number of subscribers (0 for unlimited)
    /// @param active Whether the plan is accepting new subscribers
    struct PlanConfig {
        address creator;
        address paymentToken;
        uint256 price;
        uint32 billingPeriod;
        uint32 gracePeriod;
        uint32 maxSubscribers;
        bool active;
    }

    /// @notice Metadata for a subscription plan
    /// @param name Human-readable plan name
    /// @param description Plan description
    /// @param metadataURI URI for additional metadata (IPFS, etc.)
    struct PlanMetadata {
        string name;
        string description;
        string metadataURI;
    }

    // =========================================================================
    // Events
    // =========================================================================

    /// @notice Emitted when a new subscription plan is created
    /// @param planId Unique identifier for the plan
    /// @param creator Address of the plan creator
    /// @param paymentToken Token used for payments
    /// @param price Price per billing period
    /// @param billingPeriod Duration of billing period in seconds
    event PlanCreated(
        uint256 indexed planId,
        address indexed creator,
        address indexed paymentToken,
        uint256 price,
        uint32 billingPeriod
    );

    /// @notice Emitted when a plan is updated
    /// @param planId Plan identifier
    /// @param newPrice Updated price (0 if unchanged)
    /// @param active Updated active status
    event PlanUpdated(uint256 indexed planId, uint256 newPrice, bool active);

    /// @notice Emitted when a plan is deactivated
    /// @param planId Plan identifier
    event PlanDeactivated(uint256 indexed planId);

    // =========================================================================
    // Errors
    // =========================================================================

    /// @notice Thrown when caller is not the plan creator
    error NotPlanCreator();

    /// @notice Thrown when plan does not exist
    error PlanNotFound();

    /// @notice Thrown when plan is not active
    error PlanNotActive();

    /// @notice Thrown when price is zero
    error InvalidPrice();

    /// @notice Thrown when billing period is too short
    error InvalidBillingPeriod();

    /// @notice Thrown when payment token is not supported
    error UnsupportedPaymentToken();

    // =========================================================================
    // Functions
    // =========================================================================

    /// @notice Creates a new subscription plan
    /// @param config Plan configuration
    /// @param metadata Plan metadata
    /// @return planId Unique identifier for the created plan
    function createPlan(
        PlanConfig calldata config,
        PlanMetadata calldata metadata
    ) external returns (uint256 planId);

    /// @notice Updates an existing plan's price
    /// @param planId Plan to update
    /// @param newPrice New price per billing period
    function updatePlanPrice(uint256 planId, uint256 newPrice) external;

    /// @notice Activates or deactivates a plan
    /// @param planId Plan to update
    /// @param active New active status
    function setPlanActive(uint256 planId, bool active) external;

    /// @notice Retrieves plan configuration
    /// @param planId Plan identifier
    /// @return config Plan configuration
    function getPlan(uint256 planId) external view returns (PlanConfig memory config);

    /// @notice Retrieves plan metadata
    /// @param planId Plan identifier
    /// @return metadata Plan metadata
    function getPlanMetadata(uint256 planId) external view returns (PlanMetadata memory metadata);

    /// @notice Gets all plans created by an address
    /// @param creator Creator address
    /// @return planIds Array of plan IDs
    function getCreatorPlans(address creator) external view returns (uint256[] memory planIds);

    /// @notice Returns the total number of plans created
    /// @return count Total plan count
    function totalPlans() external view returns (uint256 count);
}
